#!/usr/bin/env zsh
set -euo pipefail

# Color functions
info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

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
    export DOTFILES_PROFILE="personal"
    ;;
  2)
    export DOTFILES_PROFILE="work"
    ;;
  *)
    error "Invalid choice. Please run the script again and select 1 or 2."
    exit 1
    ;;
esac

info "Using $DOTFILES_PROFILE profile"

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
         scripts/vscode-extensions.sh || { error "Failed to make scripts executable"; exit 1; }

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
./scripts/sync.sh || { error "sync.sh failed"; exit 1; }

success "Setup complete!"
