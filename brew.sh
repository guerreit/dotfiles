# Install command-line tools using Homebrew

# Get it
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed formulae
brew upgrade

# versions
brew tap homebrew/versions

brew install bash
brew install bash-completion

# Install more recent versions of some OS X tools
brew install vim --override-system-vi

# Install other useful binaries
brew install git

# This installs `npm` too using the recommended installation method
brew install node

# Remove outdated versions from the cellar
brew cleanup
