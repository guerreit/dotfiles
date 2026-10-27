#!/usr/bin/env zsh
set -euo pipefail

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

# Common casks for both profiles
COMMON_CASKS=(visual-studio-code spotify copilot-cli)

# Profile-specific casks
if [[ "$DOTFILES_PROFILE" == "work" ]]; then
    PROFILE_CASKS=(postman microsoft-edge microsoft-teams microsoft-onenote slack)
else
    PROFILE_CASKS=(chatgpt)
fi

# Combine common and profile-specific casks
CASKS=("${COMMON_CASKS[@]}" "${PROFILE_CASKS[@]}")
INSTALLED_CASKS="$(brew list --cask)"

for cask in "${CASKS[@]}"; do
  if grep -q "^${cask}$" <<<"$INSTALLED_CASKS"; then
    info "$cask already installed."
  else
    info "Installing $cask..."
    if ! brew install --cask "$cask"; then
        error "Failed to install $cask"
        exit 1
    fi
  fi
done

success "Casks Installed!"
