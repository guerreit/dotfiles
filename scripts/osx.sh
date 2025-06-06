#!/usr/bin/env zsh
set -euo pipefail

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }

info "Disabling window animations..."
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false

info "Disabling smooth scrolling..."
defaults write -g NSScrollAnimationEnabled -bool false

info "Disabling focus ring animation..."
defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false

success "OSX Updates Complete!"
