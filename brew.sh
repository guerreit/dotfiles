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

#bash 4
brew install bash
brew install bash-completion
brew install homebrew/completions/brew-cask-completion

brew install git
brew install mongodb
brew install node
brew install z

# Switch to using brew-installed bash as default shell
if ! fgrep -q '/usr/local/bin/bash' /etc/shells; then
  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells;
  chsh -s /usr/local/bin/bash;
fi;

# Remove outdated versions from the cellar
brew cleanup
