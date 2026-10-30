#!/usr/bin/env zsh
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly REPO_ROLES_FILE="$REPO_ROOT/src/.gitconfig.roles"
readonly HOME_ROLES_FILE="$HOME/.gitconfig.roles"
source "$SCRIPT_DIR/git-identity.zsh"

ROLES_FILE=""
if [[ -f "$REPO_ROLES_FILE" ]]; then
  ROLES_FILE="$REPO_ROLES_FILE"
elif [[ -f "$HOME_ROLES_FILE" ]]; then
  ROLES_FILE="$HOME_ROLES_FILE"
fi

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

# Check if Git is installed
if ! command -v git &>/dev/null; then
  error "Git is not installed"
  exit 2
fi

# Check Git version
GIT_VERSION=$(git --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
GIT_MAJOR=$(echo "$GIT_VERSION" | cut -d. -f1)
GIT_MINOR=$(echo "$GIT_VERSION" | cut -d. -f2)

if [[ $GIT_MAJOR -lt 2 ]] || [[ $GIT_MAJOR -eq 2 && $GIT_MINOR -lt 36 ]]; then
  warning "Git version $GIT_VERSION detected (2.36+ required for remote-based conditional includes)"
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

RAW_REMOTE=""
EFFECTIVE_REMOTE=""
EXPECTED_NAME=""
EXPECTED_EMAIL=""

if git rev-parse --git-dir &>/dev/null 2>&1; then
  CURRENT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  RAW_REMOTE=$(git config --get remote.origin.url 2>/dev/null || true)
  EFFECTIVE_REMOTE=$(git remote get-url origin 2>/dev/null || true)
  echo "Detection Context:"
  echo "  Repository Root:  $CURRENT_DIR"
  echo "  Raw Remote:       ${RAW_REMOTE:-(none)}"
  echo "  Effective Remote: ${EFFECTIVE_REMOTE:-(none)}"

  resolve_git_identity "$CURRENT_DIR" "$RAW_REMOTE"
  [[ "$GIT_IDENTITY_MATCHED_OWNER" != "none" ]] && echo "  Matched Owner:    $GIT_IDENTITY_MATCHED_OWNER"
  [[ "$GIT_IDENTITY_MATCHED_PATTERN" != "none" ]] && echo "  Matched Pattern:  $GIT_IDENTITY_MATCHED_PATTERN"
  echo "  Detection Method: $GIT_IDENTITY_DETECTION_METHOD"
  echo ""
else
  GIT_IDENTITY_ROLE="${GIT_DEFAULT_ROLE:-personal}"
  warning "Not in a Git repository - showing global configuration"
  echo ""
fi

# Set expected credentials based on determined role
if [[ "$GIT_IDENTITY_ROLE" == "work" ]]; then
  EXPECTED_NAME="${GIT_WORK_NAME:-}"
  EXPECTED_EMAIL="${GIT_WORK_EMAIL:-}"
else
  EXPECTED_NAME="${GIT_PERSONAL_NAME:-}"
  EXPECTED_EMAIL="${GIT_PERSONAL_EMAIL:-}"
fi

echo "Expected Configuration for Role:"
echo "  Role:  $GIT_IDENTITY_ROLE"
echo "  Name:  $EXPECTED_NAME"
echo "  Email: $EXPECTED_EMAIL"
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

if [[ -z "$ROLES_FILE" ]]; then
  error "Missing roles configuration (expected $REPO_ROLES_FILE or $HOME_ROLES_FILE)"
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
  if [[ -n "$EXPECTED_NAME" && -n "$EXPECTED_EMAIL" ]]; then
    if [[ "$CURRENT_NAME" != "$EXPECTED_NAME" ]]; then
      warning "Name mismatch: current='$CURRENT_NAME' expected='$EXPECTED_NAME'"
      ISSUES_FOUND=true
    fi
    if [[ "$CURRENT_EMAIL" != "$EXPECTED_EMAIL" ]]; then
      warning "Email mismatch: current='$CURRENT_EMAIL' expected='$EXPECTED_EMAIL'"
      ISSUES_FOUND=true
    fi
  fi
fi

# Check for includeIf directives in .gitconfig
if grep -q "includeIf" "$HOME/.gitconfig" 2>/dev/null; then
  success "Conditional includes are configured"
else
  warning "No conditional includes found in .gitconfig"
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
