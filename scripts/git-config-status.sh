#!/usr/bin/env zsh
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly REPO_ROLES_FILE="$REPO_ROOT/src/.gitconfig.roles"
source "$SCRIPT_DIR/git-identity.zsh"

ROLES_FILE=""
[[ -f "$REPO_ROLES_FILE" ]] && ROLES_FILE="$REPO_ROLES_FILE"

# Color functions
info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}✓%f $1"; }
error() { print -P "%F{red}✗%f $1" >&2; }
warning() { print -P "%F{yellow}⚠%f $1"; }

# Usage information
usage() {
  local exit_code="${1:-0}"
  cat <<EOF
Git Configuration Status Tool
==============================

Usage: $0 [OPTIONS]

Options:
  --dry-run    Test pattern matching without executing
  -h, --help   Show this help message

Description:
  Displays your current Git configuration and verifies role-based setup.
  Shows which identity (personal/work) is active based on directory location.

EOF
  exit "$exit_code"
}

# Parse arguments
DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      error "Unknown option: $1"
      usage 1
      ;;
  esac
done

echo ""
echo "Git Configuration Status"
echo "========================"
echo ""

GIT_SUPPORT=0
git_role_rules_support || GIT_SUPPORT=$?
if (( GIT_SUPPORT == 2 )); then
  error "Git is not installed"
  exit 2
elif (( GIT_SUPPORT == 1 )); then
  warning "Git version $GIT_VERSION_FOUND detected ($GIT_ROLE_RULES_MIN_VERSION+ required for remote-based conditional includes)"
  echo ""
fi

# Get current Git configuration
CURRENT_NAME=$(git config user.name 2>/dev/null || echo "(not set)")
CURRENT_EMAIL=$(git config user.email 2>/dev/null || echo "(not set)")

echo "Active Configuration:"
echo "  Name:  $CURRENT_NAME"
echo "  Email: $CURRENT_EMAIL"
echo ""

# Load identity settings once, using the same defaults as config generation.
ROLES_CONFIG_ERROR=false
if [[ -n "$ROLES_FILE" ]]; then
  if ! load_git_identity_config "$ROLES_FILE"; then
    error "Failed to load roles configuration: $ROLES_FILE"
    ROLES_CONFIG_ERROR=true
  fi
else
  load_git_identity_config ""
fi

# Gather what git sees; the identity module decides what it means.
GIT_DIR_PATH=""
EFFECTIVE_REMOTE=""
typeset -a REMOTE_URLS=()
if GIT_DIR_PATH=$(git rev-parse --absolute-git-dir 2>/dev/null); then
  EFFECTIVE_REMOTE=$(git remote get-url origin 2>/dev/null || true)
  # origin first: it decides the expected SSH alias.
  REMOTE_URLS=(${(f)"$(git config --get remote.origin.url 2>/dev/null || true)"})
  REMOTE_URLS+=(${(f)"$(git config --get-regexp '^remote\..*\.url$' 2>/dev/null | grep -v '^remote\.origin\.url ' | cut -d' ' -f2- || true)"})
else
  GIT_DIR_PATH=""
fi

resolve_git_identity "$GIT_DIR_PATH" "${REMOTE_URLS[@]}"

if [[ -n "$GIT_DIR_PATH" ]]; then
  echo "Detection Context:"
  echo "  Repository Root:  $(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  echo "  Remotes:          ${(j:, :)REMOTE_URLS:-(none)}"
  echo "  Effective Origin: ${EFFECTIVE_REMOTE:-(none)}"
  [[ "$GIT_IDENTITY_MATCHED_OWNER" != "none" ]] && echo "  Matched Owner:    $GIT_IDENTITY_MATCHED_OWNER"
  [[ "$GIT_IDENTITY_MATCHED_PATTERN" != "none" ]] && echo "  Matched Pattern:  $GIT_IDENTITY_MATCHED_PATTERN"
  echo "  Detection Method: $GIT_IDENTITY_DETECTION_METHOD"
  echo ""
else
  warning "Not in a Git repository - showing global configuration"
  echo ""
fi

[[ -n "$GIT_IDENTITY_CASE_HINT" ]] && { warning "$GIT_IDENTITY_CASE_HINT"; echo ""; }

echo "Expected Configuration for Role:"
echo "  Role:  $GIT_IDENTITY_ROLE"
echo "  Name:  $GIT_IDENTITY_NAME"
echo "  Email: $GIT_IDENTITY_EMAIL"
echo ""

# Show configured patterns
if [[ -n "$ROLES_FILE" ]]; then
  echo "Roles Configuration File:"
  echo "  $ROLES_FILE"
  echo ""

  echo "Configured Work Patterns:"
  if (( ${#GIT_WORK_PATTERNS[@]} > 0 )); then
    for pattern in "${GIT_WORK_PATTERNS[@]}"; do
      echo "  - $pattern"
    done
  else
    echo "  (none configured)"
  fi
  echo ""

  echo "Default Role: ${GIT_DEFAULT_ROLE:-personal}"
  echo ""
fi

# Validation checks
ISSUES_FOUND=false
[[ "$ROLES_CONFIG_ERROR" == "true" ]] && ISSUES_FOUND=true

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry Run Mode: Pattern matching evaluated without validation checks"
  echo ""
  exit 0
fi

echo "Configuration Validation:"

# Check if config files exist
if [[ ! -f "$HOME/.gitconfig" ]]; then
  error "Missing ~/.gitconfig"
  ISSUES_FOUND=true
else
  success "~/.gitconfig exists"
fi

if [[ ! -f "$HOME/.gitconfig.personal" ]]; then
  error "Missing ~/.gitconfig.personal"
  ISSUES_FOUND=true
else
  success "~/.gitconfig.personal exists"
fi

if [[ ! -f "$HOME/.gitconfig.work" ]]; then
  error "Missing ~/.gitconfig.work"
  ISSUES_FOUND=true
else
  success "~/.gitconfig.work exists"
fi

if [[ ! -f "$HOME/.gitconfig.role-rules" ]]; then
  error "Missing ~/.gitconfig.role-rules (run ./dotfiles sync)"
  ISSUES_FOUND=true
else
  success "~/.gitconfig.role-rules exists"
fi

if [[ -z "$ROLES_FILE" ]]; then
  error "Missing roles configuration (expected $REPO_ROLES_FILE)"
  ISSUES_FOUND=true
else
  success "Roles configuration exists ($ROLES_FILE)"
fi

# Validate .gitconfig syntax
if git config --list &>/dev/null; then
  success "Git configuration syntax is valid"
else
  error "Git configuration has syntax errors"
  ISSUES_FOUND=true
fi

# Check if user.name and user.email are set
if [[ "$CURRENT_NAME" == "(not set)" || "$CURRENT_EMAIL" == "(not set)" ]]; then
  error "Git user.name or user.email not configured"
  ISSUES_FOUND=true
else
  success "Git identity is configured"

  # Validate that current config matches expected role
  if [[ -n "$GIT_IDENTITY_NAME" && -n "$GIT_IDENTITY_EMAIL" ]]; then
    if [[ "$CURRENT_NAME" != "$GIT_IDENTITY_NAME" ]]; then
      warning "Name mismatch: current='$CURRENT_NAME' expected='$GIT_IDENTITY_NAME'"
      ISSUES_FOUND=true
    fi
    if [[ "$CURRENT_EMAIL" != "$GIT_IDENTITY_EMAIL" ]]; then
      warning "Email mismatch: current='$CURRENT_EMAIL' expected='$GIT_IDENTITY_EMAIL'"
      ISSUES_FOUND=true
    fi
  fi
fi

# Check that ~/.gitconfig pulls in the generated role rules
if git config --file "$HOME/.gitconfig" --get-all include.path 2>/dev/null | grep -qx "~/.gitconfig.role-rules"; then
  success "~/.gitconfig includes the Git role rules"
else
  warning "~/.gitconfig does not include ~/.gitconfig.role-rules"
  warning "Role-based switching may not be active"
fi

# Validate that known GitHub owners are rewritten to the expected SSH alias.
if [[ -n "$GIT_IDENTITY_SSH_ALIAS" ]]; then
  if [[ "$EFFECTIVE_REMOTE" == "git@$GIT_IDENTITY_SSH_ALIAS:"* ]]; then
    success "Remote uses the expected SSH alias ($GIT_IDENTITY_SSH_ALIAS)"
  else
    error "Remote is not routed through $GIT_IDENTITY_SSH_ALIAS"
    ISSUES_FOUND=true
  fi

  EXPECTED_IDENTITY=$(ssh -G "$GIT_IDENTITY_SSH_ALIAS" 2>/dev/null | awk '/^identityfile / { print $2; exit }')
  if [[ -n "$EXPECTED_IDENTITY" ]]; then
    success "SSH alias selects $EXPECTED_IDENTITY"
  else
    error "SSH alias $GIT_IDENTITY_SSH_ALIAS has no IdentityFile"
    ISSUES_FOUND=true
  fi
fi

echo ""

# Final status
if [[ "$ISSUES_FOUND" == "true" ]]; then
  echo "Status: ✗ Configuration issues detected"
  echo ""
  echo "Remediation Steps:"
  echo "  1. Run: $REPO_ROOT/scripts/sync.sh"
  echo "  2. Edit $REPO_ROLES_FILE to customize your identities"
  echo "  3. Run this script again to verify"
  echo ""
  exit 1
else
  echo "Status: ✓ Configuration is valid and matches expected role"
  echo ""
fi

exit 0
