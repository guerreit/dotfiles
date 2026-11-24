#!/usr/bin/env zsh
set -euo pipefail

REPO_ROOT="$(cd "${0:A:h}/.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home"
mkdir -p "$HOME"

source "$REPO_ROOT/scripts/git-identity.zsh"

cat > "$SANDBOX/minimal-roles" <<'EOF'
GIT_DEFAULT_ROLE="work"
EOF
load_git_identity_config "$SANDBOX/minimal-roles"
[[ ${#GIT_PERSONAL_GITHUB_OWNERS[@]} -eq 0 ]]
[[ "${GIT_PERSONAL_SSH_ALIASES[1]}" == "github.com-personal" ]]
resolve_git_identity "$HOME/code/repo" ""
[[ "$GIT_IDENTITY_ROLE" == "work" && "$GIT_IDENTITY_DETECTION_METHOD" == "Default role" ]]

cat > "$SANDBOX/invalid-roles" <<'EOF'
false
EOF
if load_git_identity_config "$SANDBOX/invalid-roles"; then
  print -u2 -- "Expected invalid roles configuration to fail"
  exit 1
fi
[[ ${#GIT_WORK_PATTERNS[@]} -eq 0 ]]

cat > "$SANDBOX/roles" <<'EOF'
GIT_DEFAULT_ROLE="personal"
GIT_PERSONAL_GITHUB_OWNERS=("personal-org")
GIT_WORK_GITHUB_OWNERS=("work-org" "Slalom")
GIT_WORK_BITBUCKET_OWNERS=("work-team")
GIT_WORK_SSH_ALIASES=("github.com-work")
GIT_WORK_PATTERNS=("~/work/**")
EOF
load_git_identity_config "$SANDBOX/roles"

resolve_git_identity "$HOME/work/Example" ""
[[ "$GIT_IDENTITY_ROLE" == "work" ]]
[[ "$GIT_IDENTITY_MATCHED_PATTERN" == "~/work/**" ]]
[[ "$GIT_IDENTITY_DETECTION_METHOD" == "Directory fallback" ]]

resolve_git_identity "$HOME/work/example" "https://github.com/personal-org/project.git"
[[ "$GIT_IDENTITY_ROLE" == "personal" ]]
[[ "$GIT_IDENTITY_MATCHED_OWNER" == "github.com/personal-org" ]]
[[ "$GIT_IDENTITY_SSH_ALIAS" == "github.com-personal" ]]
[[ "$GIT_IDENTITY_DETECTION_METHOD" == "Remote owner" ]]

resolve_git_identity "$HOME/code/example" "git@github.com-work:work-org/project.git"
[[ "$GIT_IDENTITY_ROLE" == "work" ]]
[[ "$GIT_IDENTITY_SSH_ALIAS" == "github.com-work" ]]

resolve_git_identity "$HOME/code/example" "https://github.com/Slalom/project.git"
[[ "$GIT_IDENTITY_ROLE" == "work" ]]
[[ "$GIT_IDENTITY_MATCHED_OWNER" == "github.com/Slalom" ]]

resolve_git_identity "$HOME/code/example" "https://bitbucket.org/work-team/project.git"
[[ "$GIT_IDENTITY_ROLE" == "work" ]]
[[ "$GIT_IDENTITY_MATCHED_OWNER" == "bitbucket.org/work-team" ]]

print 'PASS: shared Git identity defaults, directory fallback and remote-owner precedence'

# Rendering: compare against the known-good files. After an intended change,
# refresh them by rendering tests/fixtures/git-role-rules/roles into expected/.
FIXTURE="$REPO_ROOT/tests/fixtures/git-role-rules"
unset GIT_PERSONAL_SSH_ALIASES GIT_WORK_SSH_ALIASES GIT_WORK_PATTERNS \
  GIT_PERSONAL_GITHUB_OWNERS GIT_WORK_GITHUB_OWNERS GIT_WORK_BITBUCKET_OWNERS
load_git_identity_config "$FIXTURE/roles"
mkdir "$SANDBOX/rendered"
render_git_identity_configs "$SANDBOX/rendered"
diff -r "$FIXTURE/expected" "$SANDBOX/rendered"

# The rendered rules select the right identity in real git.
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
cp "$SANDBOX/rendered"/.gitconfig.* "$HOME/"
print '[include]\n\tpath = ~/.gitconfig.role-rules' > "$HOME/.gitconfig"
check_email() {
  local dir="$1" remote="$2" expected="$3"
  mkdir -p "$dir"
  git -C "$dir" init -q
  [[ -n "$remote" ]] && git -C "$dir" remote add origin "$remote"
  [[ "$(git -C "$dir" config user.email)" == "$expected" ]] ||
    { print -u2 -- "Expected $expected in $dir ($remote)"; return 1; }
}
check_email "$HOME/code/none" "" "pat@work.example"
check_email "$HOME/code/home" "https://github.com/pat-home/x.git" "pat@personal.example"
check_email "$HOME/work/home" "git@github.com:pat-home/x.git" "pat@personal.example"
check_email "$HOME/code/corp" "https://bitbucket.org/corp-team/x.git" "pat@work.example"

GIT_WORK_EMAIL=""
if render_git_identity_configs "$SANDBOX/rendered" 2>/dev/null; then
  print -u2 -- "Expected rendering to fail without a work email"
  exit 1
fi

print 'PASS: rendered Git role rules match known-good files and select identities in git'
