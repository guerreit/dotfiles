#!/usr/bin/env zsh
set -euo pipefail

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

if ! command -v brew &> /dev/null; then
    error "Homebrew is required but was not found. Install Homebrew first, then rerun setup."
    exit 1
fi

# Make sure we're using the latest Homebrew
brew update

# Common brews for both profiles
COMMON_BREWS=(git node nvm pyenv zoxide speedtest-cli yarn gh)

# Profile-specific brews
if [[ "$DOTFILES_PROFILE" == "work" ]]; then
    PROFILE_BREWS=(awscli azure-cli colima docker terraform)
else
    PROFILE_BREWS=()
fi

# Combine common and profile-specific brews
BREWS=("${COMMON_BREWS[@]}" "${PROFILE_BREWS[@]}")
INSTALLED_FORMULAE="$(brew list --formula)"

for pkg in "${BREWS[@]}"; do
  if grep -q "^${pkg}$" <<<"$INSTALLED_FORMULAE"; then
    info "$pkg already installed."
  else
    info "Installing $pkg..."
    brew install "$pkg" || { error "Failed to install $pkg"; exit 1; }
  fi
done

# Remove outdated versions from the cellar
brew cleanup

# Done!
success "Brews Installed!"
