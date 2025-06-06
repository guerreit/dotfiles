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

# Check dependencies
for dep in curl brew chmod; do
  if ! command -v $dep &>/dev/null; then
    error "$dep is required but not installed. Exiting."; exit 1
  fi
done

# Install oh-my-zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || { error "Failed to install oh-my-zsh"; exit 1; }
else
    success "oh-my-zsh is already installed."
fi

info "Making scripts executable..."
chmod u+x scripts/brews.sh \
         scripts/casks.sh \
         scripts/osx.sh \
         scripts/sync.sh || { error "Failed to make scripts executable"; exit 1; }

info "Running brews.sh..."
./scripts/brews.sh || { error "brews.sh failed"; exit 1; }

info "Running casks.sh..."
./scripts/casks.sh || { error "casks.sh failed"; exit 1; }

info "Running osx.sh..."
./scripts/osx.sh || { error "osx.sh failed"; exit 1; }

info "Syncing dotfiles with sync.sh..."
./scripts/sync.sh || { error "sync.sh failed"; exit 1; }

success "Setup complete!"
