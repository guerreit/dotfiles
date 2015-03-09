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
brew install bash-completion
brew install vim --override-system-vi
brew install git
brew install node
brew install z

# Remove outdated versions from the cellar
brew cleanup
