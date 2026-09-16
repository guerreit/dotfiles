#!/usr/bin/env zsh
# macOS system tweaks script
# This script disables certain UI animations for a snappier experience.

set -euo pipefail

# Ensure running on macOS
ios_name=$(uname)
if [[ "$ios_name" != "Darwin" ]]; then
  print -P "%F{red}[ERROR]%f This script is intended for macOS only." >&2
  exit 1
fi

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }

# Disable window animations
info "Disabling window animations..."
if ! defaults write -g NSAutomaticWindowAnimationsEnabled -bool false; then
  print -P "%F{red}[ERROR]%f Failed to disable window animations." >&2
fi

# Disable smooth scrolling
info "Disabling smooth scrolling..."
if ! defaults write -g NSScrollAnimationEnabled -bool false; then
  print -P "%F{red}[ERROR]%f Failed to disable smooth scrolling." >&2
fi

# Disable focus ring animation
info "Disabling focus ring animation..."
if ! defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false; then
  print -P "%F{red}[ERROR]%f Failed to disable focus ring animation." >&2
fi

success "OSX Updates Complete!"
info "Some changes may require a logout/restart to take effect."
