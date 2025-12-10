#!/usr/bin/env zsh
set -euo pipefail

# Color functions
info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

# Profile persistence function
persist_profile() {
  local profile=$1
  local roles_file="src/.gitconfig.roles"

  if [[ ! -f "$roles_file" ]]; then
    error "Configuration file $roles_file not found"
    return 1
  fi

  info "Persisting profile selection to $roles_file..."

  if sed -i.bak "s/^GIT_DEFAULT_ROLE=.*/GIT_DEFAULT_ROLE=\"$profile\"/" "$roles_file" 2>/dev/null; then
    rm -f "${roles_file}.bak"
    success "Profile '$profile' saved to configuration"
    return 0
  else
    error "Failed to update $roles_file"
    return 1
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
      if [[ -x "./scripts/ssh-key.sh" ]]; then
        ./scripts/ssh-key.sh || { error "ssh-key.sh failed"; return 1; }
      else
        error "ssh-key.sh not found or not executable"
        return 1
      fi
      ;;
    *)
      info "Skipping SSH key generation. You can run ./scripts/ssh-key.sh later if needed."
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

# Persist profile choice to configuration file
persist_profile "$DOTFILES_PROFILE" || { error "Failed to persist profile"; exit 1; }

# Export for child scripts
export DOTFILES_PROFILE

# Prompt for SSH key generation
ssh_prompt

# Check dependencies
for dep in curl brew chmod; do
  if ! command -v $dep &>/dev/null; then
    error "$dep is required but not installed. Exiting."; exit 1
  fi
done

info "Making scripts executable..."
chmod u+x scripts/brews.sh \
         scripts/casks.sh \
         scripts/osx.sh \
         scripts/sync.sh \
         scripts/plugins.sh \
         scripts/vscode-extensions.sh \
         scripts/backup.sh \
         scripts/git-config-status.sh || { error "Failed to make scripts executable"; exit 1; }

info "Creating backup of existing dotfiles..."
./scripts/backup.sh || { error "backup.sh failed"; exit 1; }

info "Installing plugins..."
./scripts/plugins.sh || { error "plugins.sh failed"; exit 1; }

info "Running brews.sh..."
./scripts/brews.sh || { error "brews.sh failed"; exit 1; }

info "Running casks.sh..."
./scripts/casks.sh || { error "casks.sh failed"; exit 1; }

info "Configuring VS Code extensions..."
./scripts/vscode-extensions.sh || { error "vscode-extensions.sh failed"; exit 1; }

info "Running osx.sh..."
./scripts/osx.sh || { error "osx.sh failed"; exit 1; }

info "Syncing dotfiles with sync.sh..."
./scripts/sync.sh "$DOTFILES_PROFILE" || { error "sync.sh failed"; exit 1; }

success "Setup complete!"

# Display Git configuration status
info "Checking Git configuration..."
./scripts/git-config-status.sh || true
