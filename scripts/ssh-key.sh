#!/usr/bin/env zsh
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly ROLES_FILE="$REPO_ROOT/src/.gitconfig.roles"
readonly SSH_CONFIG_TEMPLATE="$REPO_ROOT/src/.ssh_config"

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }
warning() { print -P "%F{yellow}[WARNING]%f $1"; }

# Source email addresses from configuration file
source_emails() {
  if [[ -f "$ROLES_FILE" ]]; then
    if source "$ROLES_FILE" 2>/dev/null; then
      # Extract emails if variables are set
      if [[ -n "${GIT_PERSONAL_EMAIL:-}" ]]; then
        PERSONAL_EMAIL="$GIT_PERSONAL_EMAIL"
      fi
      if [[ -n "${GIT_WORK_EMAIL:-}" ]]; then
        WORK_EMAIL="$GIT_WORK_EMAIL"
      fi
    else
      warning "Failed to source $ROLES_FILE, using default email addresses"
    fi
  else
    warning "Configuration file $ROLES_FILE not found, using default email addresses"
  fi
}

add_key_to_agent() {
  local key_file="$1"

  if ! ssh-add --apple-use-keychain "$key_file" 2>/dev/null; then
    ssh-add "$key_file"
  fi
}

install_ssh_config() {
  if [[ ! -f "$SSH_CONFIG_TEMPLATE" ]]; then
    error "SSH config template not found: $SSH_CONFIG_TEMPLATE"
    return 1
  fi

  if [[ -f "$CONFIG_FILE" ]] && ! cmp -s "$SSH_CONFIG_TEMPLATE" "$CONFIG_FILE"; then
    local backup_file="$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file"
    info "Backed up existing SSH config to $backup_file"
  fi

  cp "$SSH_CONFIG_TEMPLATE" "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
  success "Installed SSH config from $SSH_CONFIG_TEMPLATE"
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

add_key_to_agent "$PERSONAL_KEY"
add_key_to_agent "$WORK_KEY"
install_ssh_config

# Set permissions
chmod 600 "$PERSONAL_KEY" "$WORK_KEY"
chmod 644 "$PERSONAL_KEY.pub" "$WORK_KEY.pub"

# Print public keys and copy to clipboard
echo ""
echo "Public key for PERSONAL GitHub (add to https://github.com/settings/ssh/new):"
cat "$PERSONAL_KEY.pub"
pbcopy < "$PERSONAL_KEY.pub"
info "Personal public key copied to clipboard. Paste it at https://github.com/settings/ssh/new, then press Enter to continue..."
read -r _

echo ""
echo "Public key for WORK GitHub (add to https://github.com/settings/ssh/new):"
cat "$WORK_KEY.pub"
pbcopy < "$WORK_KEY.pub"
info "Work public key copied to clipboard. Paste it at https://github.com/settings/ssh/new when ready."

echo ""
success "Done. Use the following Git remote URLs:"
echo "  Personal: git@github.com-personal:yourusername/repo.git"
echo "  Work:     git@github.com-work:yourworkusername/repo.git"
