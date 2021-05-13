#!/bin/bash

# Get brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed brews
brew upgrade

# cask
brew tap homebrew/cask

# brews i need
brew install aws-sam-cli
brew install awscli
brew install git
brew install node
brew install nvm
brew install rbenv
brew install pyenv
brew install speedtest=cli
brew install yarn

# Remove outdated versions from the cellar
brew cleanup
