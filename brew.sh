#!/bin/bash

# Get brew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed brews
brew upgrade

# versions
brew tap homebrew/versions

# cask
brew tap caskroom/cask

# casks i need
brew install git
brew install mongodb
brew install node
brew install z

# Remove outdated versions from the cellar
brew cleanup
