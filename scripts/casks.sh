#!/usr/bin/env zsh
set -euo pipefail

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

# Upgrade all installed casks
brew upgrade --cask || { error "brew upgrade --cask failed"; exit 1; }

# Common casks for both profiles
COMMON_CASKS=(visual-studio-code)

# Profile-specific casks
if [[ "$DOTFILES_PROFILE" == "work" ]]; then
    PROFILE_CASKS=(postman microsoft-edge microsoft-teams slack)
else
    PROFILE_CASKS=()
fi

# Combine common and profile-specific casks
CASKS=($COMMON_CASKS $PROFILE_CASKS)

for cask in $CASKS; do
  if brew list --cask | grep -q "^$cask$"; then
    info "$cask already installed."
  else
    info "Installing $cask..."
    brew install --cask $cask || { error "Failed to install $cask"; exit 1; }
  fi
done

success "Casks Installed!"
