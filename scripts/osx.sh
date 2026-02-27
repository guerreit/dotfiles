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

# Configure screenshot location
readonly SCREENSHOT_DIR="${HOME}/Desktop/screenshots"
info "Configuring screenshots to save to ${SCREENSHOT_DIR}..."

# Create screenshots directory if it doesn't exist
if [[ ! -d "$SCREENSHOT_DIR" ]]; then
  if mkdir -p "$SCREENSHOT_DIR"; then
    info "Created directory: ${SCREENSHOT_DIR}"
  else
    print -P "%F{red}[ERROR]%f Failed to create screenshot directory." >&2
  fi
fi

# Set screenshot location
if ! defaults write com.apple.screencapture location "$SCREENSHOT_DIR"; then
  print -P "%F{red}[ERROR]%f Failed to set screenshot location." >&2
fi

# Disable screenshot thumbnail preview (optional - remove if you want the preview)
if ! defaults write com.apple.screencapture show-thumbnail -bool false; then
  print -P "%F{red}[ERROR]%f Failed to disable screenshot thumbnail." >&2
fi

# Apply screenshot changes
info "Applying screenshot settings..."
if ! killall SystemUIServer 2>/dev/null; then
  print -P "%F{yellow}[WARN]%f Could not restart SystemUIServer." >&2
fi

success "OSX Updates Complete!"
info "Some changes may require a logout/restart to take effect."
