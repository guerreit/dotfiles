#!/usr/bin/env bash
set -euo pipefail

# Color functions
info() { echo -e "\033[1;36m[INFO]\033[0m $1"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }
warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }

# Source email addresses from configuration file
source_emails() {
  local roles_file="src/.gitconfig.roles"

  # Try to source the roles file
  if [[ -f "$roles_file" ]]; then
    if source "$roles_file" 2>/dev/null; then
      # Extract emails if variables are set
      if [[ -n "${GIT_PERSONAL_EMAIL:-}" ]]; then
        PERSONAL_EMAIL="$GIT_PERSONAL_EMAIL"
      fi
      if [[ -n "${GIT_WORK_EMAIL:-}" ]]; then
        WORK_EMAIL="$GIT_WORK_EMAIL"
      fi
    else
      warning "Failed to source $roles_file, using default email addresses"
    fi
  else
    warning "Configuration file $roles_file not found, using default email addresses"
  fi
}

# Usage
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  echo "Usage: ./ssh-key.sh [personal_email] [work_email]"
  echo ""
  echo "If no arguments provided, emails will be read from src/.gitconfig.roles"
  echo "or default to hardcoded values if the file is not available."
  exit 0
fi

# Default email addresses (fallback)
PERSONAL_EMAIL="${1:-garrettjones@me.com}"
WORK_EMAIL="${2:-garrettj@slalom.com}"

# Source emails from configuration file if no arguments provided
if [[ $# -eq 0 ]]; then
  source_emails
fi
SSH_DIR="$HOME/.ssh"
CONFIG_FILE="$SSH_DIR/config"
PERSONAL_KEY="$SSH_DIR/id_ed25519_github_personal"
WORK_KEY="$SSH_DIR/id_ed25519_github_work"

# Create SSH directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate personal SSH key if not exists
if [ -f "$PERSONAL_KEY" ]; then
  success "Personal SSH key already exists: $PERSONAL_KEY"
else
  info "Generating personal SSH key..."
  ssh-keygen -t ed25519 -C "$PERSONAL_EMAIL" -f "$PERSONAL_KEY" -N ""
fi

# Generate work SSH key if not exists
if [ -f "$WORK_KEY" ]; then
  success "Work SSH key already exists: $WORK_KEY"
else
  info "Generating work SSH key..."
  ssh-keygen -t ed25519 -C "$WORK_EMAIL" -f "$WORK_KEY" -N ""
fi

# Start SSH agent if not running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
  eval "$(ssh-agent -s)"
fi

# Add keys to the SSH agent
ssh-add "$PERSONAL_KEY"
ssh-add "$WORK_KEY"

# Update SSH config if entries are missing
touch "$CONFIG_FILE"

if ! grep -q "Host github.com-personal" "$CONFIG_FILE"; then
  echo -e "\n# Personal GitHub account" >> "$CONFIG_FILE"
  echo "Host github.com-personal" >> "$CONFIG_FILE"
  echo "  HostName github.com" >> "$CONFIG_FILE"
  echo "  User git" >> "$CONFIG_FILE"
  echo "  IdentityFile $PERSONAL_KEY" >> "$CONFIG_FILE"
fi

if ! grep -q "Host github.com-work" "$CONFIG_FILE"; then
  echo -e "\n# Work GitHub account" >> "$CONFIG_FILE"
  echo "Host github.com-work" >> "$CONFIG_FILE"
  echo "  HostName github.com" >> "$CONFIG_FILE"
  echo "  User git" >> "$CONFIG_FILE"
  echo "  IdentityFile $WORK_KEY" >> "$CONFIG_FILE"
fi

# Set permissions
chmod 600 "$PERSONAL_KEY" "$PERSONAL_KEY.pub" "$WORK_KEY" "$WORK_KEY.pub"
chmod 600 "$CONFIG_FILE"

# Print public keys
echo ""
echo "🔓 Public key for PERSONAL GitHub (add to https://github.com/settings/ssh/new):"
cat "$PERSONAL_KEY.pub"
echo ""
echo "🔓 Public key for WORK GitHub (add to https://github.com/settings/ssh/new):"
cat "$WORK_KEY.pub"
echo ""
success "Done. Use the following Git remote URLs:"
echo "  Personal: git@github.com-personal:yourusername/repo.git"
echo "  Work:     git@github.com-work:yourworkusername/repo.git"
