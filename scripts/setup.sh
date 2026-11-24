#!/usr/bin/env zsh
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SCRIPTS_DIR="$REPO_ROOT/scripts"
readonly ROLES_FILE="$REPO_ROOT/src/.gitconfig.roles"
source "$SCRIPTS_DIR/git-identity.zsh"

# Color functions
info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

# Asks for this machine's default Git role. It is independent of the
# installation profile (docs/adr/0001) and is stored machine-locally in
# src/.gitconfig.roles.local only when it differs from the shared default.
default_role_prompt() {
  local local_file="$ROLES_FILE.local" tracked answer
  tracked="$(zsh -c 'source "$1" >/dev/null 2>&1; print -r -- "${GIT_DEFAULT_ROLE:-personal}"' _ "$ROLES_FILE")"
  load_git_identity_config "$ROLES_FILE" || { error "Fix $ROLES_FILE before running setup"; exit 1; }

  echo ""
  echo "Default Git role on this machine, for repositories no owner or directory rule matches."
  echo "This is separate from the installation profile."
  read "answer?Default role [personal/work] ($GIT_DEFAULT_ROLE): "
  answer="${answer:-$GIT_DEFAULT_ROLE}"
  case "$answer" in
    personal|work) ;;
    *) error "Enter personal or work."; exit 1 ;;
  esac

  if [[ "$answer" != "$tracked" || -f "$local_file" ]]; then
    print -r -- "GIT_DEFAULT_ROLE=\"$answer\"" > "$local_file"
    info "Saved this machine's default Git role ($answer) to src/.gitconfig.roles.local"
  else
    info "Using the shared default Git role ($tracked)"
  fi
}

# SSH key generation prompt
ssh_prompt() {
  echo ""
  echo "Generate SSH keys for Git authentication?"
  echo "This will create separate keys for personal and work GitHub accounts."
  read "ssh_choice?Generate SSH keys? [y/N]: "

  case $ssh_choice in
    [Yy]*)
      info "Generating SSH keys..."
      if [[ -x "$SCRIPTS_DIR/ssh-key.sh" ]]; then
        "$SCRIPTS_DIR/ssh-key.sh" || { error "ssh-key.sh failed"; return 1; }
      else
        error "ssh-key.sh not found or not executable"
        return 1
      fi
      ;;
    *)
      info "Skipping SSH key generation. You can run $SCRIPTS_DIR/ssh-key.sh later if needed."
      ;;
  esac
  echo ""
}

# Usage
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  echo "Usage: ./setup.sh"
  echo "Installs oh-my-zsh, makes scripts executable, installs brews/casks, applies OSX tweaks, and syncs dotfiles."
  exit 0
fi

# Prompt for profile selection
echo "Select your profile:"
echo "1) Personal"
echo "2) Work"
read "profile_choice?Enter your choice (1 or 2): "

case $profile_choice in
  1)
    DOTFILES_PROFILE="personal"
    ;;
  2)
    DOTFILES_PROFILE="work"
    ;;
  *)
    error "Invalid choice. Please run the script again and select 1 or 2."
    exit 1
    ;;
esac

info "Using $DOTFILES_PROFILE profile"

# Export for child scripts
export DOTFILES_PROFILE

default_role_prompt

# Prompt for SSH key generation
ssh_prompt

# Check dependencies
for dep in curl brew chmod; do
  if ! command -v "$dep" &>/dev/null; then
    error "$dep is required but not installed. Exiting."; exit 1
  fi
done

info "Making scripts executable..."
chmod u+x "$SCRIPTS_DIR"/*.sh || { error "Failed to make scripts executable"; exit 1; }

info "Creating backup of existing dotfiles..."
"$SCRIPTS_DIR/backup.sh" || { error "backup.sh failed"; exit 1; }

info "Installing plugins..."
"$SCRIPTS_DIR/plugins.sh" || { error "plugins.sh failed"; exit 1; }

info "Running brews.sh..."
"$SCRIPTS_DIR/brews.sh" || { error "brews.sh failed"; exit 1; }

info "Bootstrapping Matt Pocock skills..."
"$SCRIPTS_DIR/bootstrap-matt-pocock-skills.sh" || { error "bootstrap-matt-pocock-skills.sh failed"; exit 1; }

info "Running casks.sh..."
"$SCRIPTS_DIR/casks.sh" || { error "casks.sh failed"; exit 1; }

info "Configuring VS Code extensions..."
"$SCRIPTS_DIR/vscode-extensions.sh" || { error "vscode-extensions.sh failed"; exit 1; }

info "Running osx.sh..."
"$SCRIPTS_DIR/osx.sh" || { error "osx.sh failed"; exit 1; }

info "Syncing dotfiles with sync.sh..."
"$SCRIPTS_DIR/sync.sh" || { error "sync.sh failed"; exit 1; }

success "Setup complete!"

# Display Git configuration status
info "Checking Git configuration..."
"$SCRIPTS_DIR/git-config-status.sh" || true
