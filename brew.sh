# Install command-line tools using Homebrew

# Get brew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed formulae
brew upgrade

# versions
brew tap homebrew/versions

brew install bash
brew install brew-cask
brew install bash-completion
brew install git
brew install heroku-toolbelt
brew install mongodb
brew install node
brew install vim --override-system-vi
brew install z

# Remove outdated versions from the cellar
brew cleanup
