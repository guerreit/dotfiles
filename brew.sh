#!/bin/bash

# Get brew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed brews
brew upgrade --all

# versions
brew tap homebrew/versions

brew install bash
brew install bash-completion
brew install brew-cask
brew install git
brew install heroku-toolbelt
brew install mongodb
brew install node
brew install vim --override-system-vi
brew install wget
brew install z

# Remove outdated versions from the cellar
brew cleanup
