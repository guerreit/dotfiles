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
