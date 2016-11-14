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
brew install bash-completion2
brew install brew-cask
brew install git
brew install heroku-toolbelt
brew install mongodb
brew install node
brew install vim --override-system-vi
brew install wget
brew install z

# Switch to using brew-installed bash as default shell
if ! fgrep -q '/usr/local/bin/bash' /etc/shells; then
  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells;
  chsh -s /usr/local/bin/bash;
fi;

# Remove outdated versions from the cellar
brew cleanup
