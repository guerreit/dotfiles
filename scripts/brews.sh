#!/bin/zsh

# Get brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed brews
brew upgrade

# brews i need
brew install awscli
brew install azure-cli
brew install colima
brew install docker
brew install docker-compose
brew install git
brew install node
brew install nvm
brew install poetry
brew install pyenv
brew install speedtest-cli
brew install terraform
brew install yarn

# Remove outdated versions from the cellar
brew cleanup
