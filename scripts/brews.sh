#!/bin/zsh

# Get brew
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed"
fi

# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed brews
brew upgrade

# brews i need
brew install \
    awscli \
    azure-cli \
    colima \
    docker \
    docker-compose \
    git \
    node \
    nvm \
    poetry \
    pyenv \
    speedtest-cli \
    terraform \
    yarn || { echo "Package installation failed"; exit 1; }

# Remove outdated versions from the cellar
brew cleanup

# Done!
echo "Brews Installed!"
