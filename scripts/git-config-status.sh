#!/usr/bin/env zsh
set -euo pipefail

# Color functions
info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}✓%f $1"; }
error() { print -P "%F{red}✗%f $1" >&2; }
warning() { print -P "%F{yellow}⚠%f $1"; }

# Usage information
usage() {
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
  exit 0
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
      usage
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

if [[ $GIT_MAJOR -lt 2 ]] || [[ $GIT_MAJOR -eq 2 && $GIT_MINOR -lt 13 ]]; then
  warning "Git version $GIT_VERSION detected (2.13+ required for conditional includes)"
  echo ""
fi

# Get current Git configuration
CURRENT_NAME=$(git config user.name 2>/dev/null || echo "(not set)")
CURRENT_EMAIL=$(git config user.email 2>/dev/null || echo "(not set)")

echo "Active Configuration:"
echo "  Name:  $CURRENT_NAME"
echo "  Email: $CURRENT_EMAIL"
echo ""

# Load default role first
if [[ -f "$HOME/.gitconfig.roles" ]]; then
  source "$HOME/.gitconfig.roles" 2>/dev/null || true
fi

# Determine active role based on directory patterns
ACTIVE_ROLE="${GIT_DEFAULT_ROLE:-personal}"
MATCHED_PATTERN="none"
EXPECTED_NAME=""
EXPECTED_EMAIL=""

if git rev-parse --git-dir &>/dev/null 2>&1; then
  CURRENT_DIR=$(pwd)
  echo "Detection Context:"
  echo "  Current Directory: $CURRENT_DIR"

  # Check which pattern matched to determine role
  if [[ -n "${GIT_WORK_PATTERNS:-}" ]]; then
    for pattern in "${GIT_WORK_PATTERNS[@]}"; do
      # Expand ~ to home directory
      expanded_pattern="${pattern/#\~/$HOME}"
      # Convert glob pattern to regex for matching
      # Simple conversion: ** -> .*, * -> [^/]*
      regex_pattern="${expanded_pattern//\*\*/.*}"
      regex_pattern="${regex_pattern//\*/[^/]*}"

      if [[ "$CURRENT_DIR" =~ ^${regex_pattern} ]]; then
        MATCHED_PATTERN="$pattern"
        ACTIVE_ROLE="work"
        break
      fi
    done
  fi

  if [[ "$MATCHED_PATTERN" != "none" ]]; then
    echo "  Matched Pattern:  $MATCHED_PATTERN"
    echo "  Detection Method: Directory pattern match (overrides default)"
  else
    echo "  Matched Pattern:  (none - using default role)"
    echo "  Detection Method: Default role from configuration"
  fi
  echo ""
else
  warning "Not in a Git repository - showing global configuration"
  echo ""
fi

# Set expected credentials based on determined role
if [[ "$ACTIVE_ROLE" == "work" ]]; then
  EXPECTED_NAME="${GIT_WORK_NAME:-}"
  EXPECTED_EMAIL="${GIT_WORK_EMAIL:-}"
else
  EXPECTED_NAME="${GIT_PERSONAL_NAME:-}"
  EXPECTED_EMAIL="${GIT_PERSONAL_EMAIL:-}"
fi

echo "Expected Configuration for Role:"
echo "  Role:  $ACTIVE_ROLE"
echo "  Name:  $EXPECTED_NAME"
echo "  Email: $EXPECTED_EMAIL"
echo ""

# Show configured patterns
if [[ -f "$HOME/.gitconfig.roles" ]]; then
  source "$HOME/.gitconfig.roles" 2>/dev/null || true

  echo "Configured Work Patterns:"
  if [[ -n "${GIT_WORK_PATTERNS:-}" && ${#GIT_WORK_PATTERNS[@]} -gt 0 ]]; then
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

if [[ ! -f "$HOME/.gitconfig.roles" ]]; then
  error "Missing ~/.gitconfig.roles"
  ISSUES_FOUND=true
else
  success "~/.gitconfig.roles exists"
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

echo ""

# Final status
if [[ "$ISSUES_FOUND" == "true" ]]; then
  echo "Status: ✗ Configuration issues detected"
  echo ""
  echo "Remediation Steps:"
  echo "  1. Run: cd ~/dotfiles && ./scripts/sync.sh"
  echo "  2. Edit ~/.gitconfig.roles to customize your identities"
  echo "  3. Run this script again to verify"
  echo ""
  exit 1
else
  echo "Status: ✓ Configuration is valid and matches expected role"
  echo ""
fi

# Dry run mode information
if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry Run Mode: Pattern matching tested without execution"
  echo ""
fi

exit 0
