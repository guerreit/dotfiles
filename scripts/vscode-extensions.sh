#!/usr/bin/env zsh
# VS Code Extensions Management Script
# This script ensures only essential extensions are installed and removes unwanted ones.

set -euo pipefail

# Ensure running on macOS
ios_name=$(uname)
if [[ "$ios_name" != "Darwin" ]]; then
  print -P "%F{red}[ERROR]%f This script is intended for macOS only." >&2
  exit 1
fi

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
warn() { print -P "%F{yellow}[WARN]%f $1"; }

# Check if VS Code is installed
if ! command -v code &> /dev/null; then
  warn "VS Code CLI not found. Please install VS Code first or ensure 'code' command is available."
  exit 1
fi

# Essential extensions to install
ESSENTIAL_EXTENSIONS=(
  "dbaeumer.vscode-eslint"
  "eamodio.gitlens"
  "editorconfig.editorconfig"
  "esbenp.prettier-vscode"
  "github.copilot"
  "github.copilot-chat"
  "redhat.vscode-yaml"
)

info "Managing VS Code extensions..."

# Get currently installed extensions
INSTALLED_EXTENSIONS=($(code --list-extensions 2>/dev/null || true))

# Install essential extensions
info "Installing essential extensions..."
for ext in "${ESSENTIAL_EXTENSIONS[@]}"; do
  if [[ ! " ${INSTALLED_EXTENSIONS[@]} " =~ " ${ext} " ]]; then
    info "Installing: $ext"
    if code --install-extension "$ext" >/dev/null 2>&1; then
      success "Installed: $ext"
    else
      warn "Failed to install: $ext"
    fi
  else
    info "Already installed: $ext"
  fi
done

# Final check and report
info "Final extension list:"
FINAL_EXTENSIONS=($(code --list-extensions 2>/dev/null || true))
for ext in "${FINAL_EXTENSIONS[@]}"; do
  if [[ " ${ESSENTIAL_EXTENSIONS[@]} " =~ " ${ext} " ]]; then
    print -P "  %F{green}✓%f $ext"
  else
    print -P "  %F{yellow}?%f $ext (not in essential list)"
  fi
done

success "VS Code extensions management complete!"
info "You now have $(echo ${#FINAL_EXTENSIONS[@]}) extensions installed."
