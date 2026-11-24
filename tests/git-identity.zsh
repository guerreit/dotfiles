#!/usr/bin/env zsh
# Git identity module tests. Real git is the reference: the resolver must
# predict the identity git actually applies for every fixture repository.
set -euo pipefail

REPO_ROOT="$(cd "${0:A:h}/.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
export GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"

source "$REPO_ROOT/scripts/git-identity.zsh"
FIXTURE="$REPO_ROOT/tests/fixtures/git-role-rules"

fail() { print -u2 -- "FAIL: $*"; exit 1; }

reset_roles() {
  unset GIT_PERSONAL_NAME GIT_PERSONAL_EMAIL GIT_WORK_NAME GIT_WORK_EMAIL GIT_DEFAULT_ROLE \
    GIT_PERSONAL_SSH_ALIASES GIT_WORK_SSH_ALIASES GIT_WORK_PATTERNS \
    GIT_PERSONAL_GITHUB_OWNERS GIT_WORK_GITHUB_OWNERS GIT_WORK_BITBUCKET_OWNERS
}

# --- Loading -------------------------------------------------------------------

print 'GIT_DEFAULT_ROLE="work"' > "$SANDBOX/minimal-roles"
load_git_identity_config "$SANDBOX/minimal-roles"
[[ ${#GIT_PERSONAL_GITHUB_OWNERS[@]} -eq 0 ]] || fail "owner lists default to empty"
[[ "${GIT_PERSONAL_SSH_ALIASES[1]}" == "github.com-personal" ]] || fail "alias defaults"

reset_roles
print 'false' > "$SANDBOX/invalid-roles"
load_git_identity_config "$SANDBOX/invalid-roles" && fail "invalid roles file must fail to load"
[[ ${#GIT_WORK_PATTERNS[@]} -eq 0 ]] || fail "defaults applied after a failed load"

# Machine-local default role: only GIT_DEFAULT_ROLE is read, and it wins.
reset_roles
cp "$FIXTURE/roles" "$SANDBOX/local-roles"
print 'GIT_DEFAULT_ROLE="personal"\nGIT_WORK_EMAIL="ignored@example.test"' > "$SANDBOX/local-roles.local"
load_git_identity_config "$SANDBOX/local-roles" 2> "$SANDBOX/load.err" || fail "local override loads"
[[ "$GIT_DEFAULT_ROLE" == personal && "$GIT_DEFAULT_ROLE_SOURCE" == "local-roles.local" ]] ||
  fail "local default role wins over the tracked one ($GIT_DEFAULT_ROLE from $GIT_DEFAULT_ROLE_SOURCE)"
[[ "$GIT_WORK_EMAIL" == "pat@work.example" ]] || fail "other settings in the local file are ignored"
grep -q "Ignoring settings other than GIT_DEFAULT_ROLE" "$SANDBOX/load.err" || fail "ignored settings are reported"

reset_roles
rm "$SANDBOX/local-roles.local"
load_git_identity_config "$SANDBOX/local-roles"
[[ "$GIT_DEFAULT_ROLE" == work && "$GIT_DEFAULT_ROLE_SOURCE" == "local-roles" ]] || fail "tracked default applies without a local file"

for bad in 'GIT_DEFAULT_ROLE="foo"' 'GIT_DEFAULT_ROLE="Work"'; do
  reset_roles
  print -r -- "$bad" > "$SANDBOX/local-roles.local"
  load_git_identity_config "$SANDBOX/local-roles" 2>/dev/null && fail "invalid default role accepted: $bad"
done
rm "$SANDBOX/local-roles.local"
print 'PASS: roles loading applies shared defaults and the machine-local default role'

# --- Rendering: byte-for-byte against the known-good files -----------------------
# After an intended change, refresh them by rendering the fixture roles file
# into tests/fixtures/git-role-rules/expected/ and reviewing the diff.

reset_roles
load_git_identity_config "$FIXTURE/roles"
mkdir "$SANDBOX/rendered"
render_git_identity_configs "$SANDBOX/rendered"
diff -r "$FIXTURE/expected" "$SANDBOX/rendered" || fail "rendered output differs from known-good files"

if ( GIT_WORK_EMAIL=""; render_git_identity_configs "$SANDBOX/rendered" 2>/dev/null ); then
  fail "rendering needs every identity"
fi
[[ "$(git_identity_dead_patterns)" == "~/clients/acme" ]] || fail "dead pattern detection"
print 'PASS: rendered Git role rules match known-good files'

# --- Resolver vs real git ----------------------------------------------------------

# Deploys the rendered rules into HOME the way sync does.
deploy_rules() {
  mkdir -p "$SANDBOX/deploy"
  render_git_identity_configs "$SANDBOX/deploy"
  cp "$SANDBOX/deploy"/.gitconfig.* "$HOME/"
  print '[include]\n\tpath = ~/.gitconfig.role-rules' > "$HOME/.gitconfig"
}

# Args: label, repo folder under HOME, remote URLs (origin first, then upstream)
# Asserts the resolver predicts the email git applies, and the SSH alias git
# routes origin through. Leaves the GIT_IDENTITY_* results for extra checks.
CASE_COUNT=0
check_case() {
  local label="$1" dir="$HOME/$2"
  shift 2
  local -a names=(origin upstream)
  local i git_email git_dir

  rm -rf "$dir"
  mkdir -p "$dir"
  git -C "$dir" init -q
  for (( i = 1; i <= $#; i++ )); do
    git -C "$dir" remote add "${names[i]}" "${@[i]}"
  done

  git_email="$(git -C "$dir" config user.email)"
  git_dir="$(git -C "$dir" rev-parse --absolute-git-dir)"
  resolve_git_identity "$git_dir" "$@"

  [[ "$GIT_IDENTITY_EMAIL" == "$git_email" ]] ||
    fail "$label: resolver predicted $GIT_IDENTITY_EMAIL ($GIT_IDENTITY_ROLE via $GIT_IDENTITY_DETECTION_METHOD), git applied $git_email"
  if [[ -n "$GIT_IDENTITY_SSH_ALIAS" ]]; then
    [[ "$(git -C "$dir" remote get-url origin)" == "git@$GIT_IDENTITY_SSH_ALIAS:"* ]] ||
      fail "$label: git does not route origin through $GIT_IDENTITY_SSH_ALIAS"
  fi
  (( ++CASE_COUNT ))
}

run_oracle_cases() {
  check_case "no remote"                code/none
  check_case "personal owner, https"    code/home    https://github.com/pat-home/x.git
  check_case "owner beats directory"    work/home    git@github.com:pat-home/x.git
  check_case "work owner via alias"     code/alias   git@github.com-work:CorpOrg/x.git
  check_case "bitbucket owner"          code/bb      https://bitbucket.org/corp-team/x.git
  check_case "unknown owner"            code/other   https://github.com/someone/x.git
  check_case "unknown owner in work"    work/other   https://github.com/someone/x.git
  check_case "nested work folder"       work/a/b/c
  check_case "work folder, other case"  Work/caps
  check_case "pattern without /**"      clients/acme
  check_case "fork, work upstream"      code/fork    https://github.com/pat-home/x.git https://github.com/CorpOrg/x.git
  check_case "fork, personal upstream"  code/fork2   https://github.com/CorpOrg/x.git https://github.com/pat-home/x.git
  check_case "owner in wrong case"      code/case    https://github.com/PAT-HOME/x.git
  check_case "bitbucket wrong case"     code/bbcase  https://bitbucket.org/Corp-Team/x.git
}

for default_role in work personal; do
  reset_roles
  load_git_identity_config "$FIXTURE/roles"
  GIT_DEFAULT_ROLE="$default_role"
  deploy_rules
  run_oracle_cases
done

# Explanations the resolver adds on top of agreeing with git.
check_case "wrong case hint" code/case https://github.com/PAT-HOME/x.git
[[ "$GIT_IDENTITY_DETECTION_METHOD" == "Default role" && "$GIT_IDENTITY_CASE_HINT" == *"pat-home"* ]] ||
  fail "wrong-case owner should fall back with a case hint"
check_case "exact owner has no hint" code/home https://github.com/pat-home/x.git
[[ -z "$GIT_IDENTITY_CASE_HINT" && "$GIT_IDENTITY_MATCHED_OWNER" == "github.com/pat-home" ]] ||
  fail "exact owner match should report the owner and no hint"
check_case "directory fallback detail" Work/caps
[[ "$GIT_IDENTITY_DETECTION_METHOD" == "Directory fallback" && "$GIT_IDENTITY_MATCHED_PATTERN" == "~/work/**" ]] ||
  fail "directory fallback should report its pattern"

# Outside a repository every output is still set (status runs under set -u).
resolve_git_identity ""
[[ "$GIT_IDENTITY_ROLE" == "personal" && "$GIT_IDENTITY_EMAIL" == "pat@personal.example" ]] ||
  fail "outside a repo the default role applies"
[[ -z "$GIT_IDENTITY_SSH_ALIAS" && -z "$GIT_IDENTITY_CASE_HINT" && -z "$GIT_IDENTITY_MATCHED_RULE" ]] ||
  fail "outside a repo optional outputs are empty"

git_role_rules_support || fail "test machine git should support role rules"

print "PASS: resolver agrees with real git on $CASE_COUNT cases across both default roles"
