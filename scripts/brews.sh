#!/usr/bin/env zsh
set -euo pipefail

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

# Get brew
if ! command -v brew &> /dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    success "Homebrew already installed"
fi

# Make sure we're using the latest Homebrew
brew update

# Upgrade any already-installed brews
brew upgrade

# Common brews for both profiles
COMMON_BREWS=(git node nvm zoxide speedtest-cli yarn gh)

# Profile-specific brews
if [[ "$DOTFILES_PROFILE" == "work" ]]; then
    PROFILE_BREWS=(awscli azure-cli terraform)
else
    PROFILE_BREWS=()
fi

# Combine common and profile-specific brews
BREWS=($COMMON_BREWS $PROFILE_BREWS)

for pkg in $BREWS; do
  if brew list --formula | grep -q "^$pkg$"; then
    info "$pkg already installed."
  else
    info "Installing $pkg..."
    brew install $pkg || { error "Failed to install $pkg"; exit 1; }
  fi
done

# Remove outdated versions from the cellar
brew cleanup

# Done!
success "Brews Installed!"
