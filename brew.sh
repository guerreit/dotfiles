#!/bin/zsh

# Get brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed brews
brew upgrade

# cask
brew tap homebrew/cask

# brews i need
brew install git
brew install node

# Remove outdated versions from the cellar
brew cleanup
