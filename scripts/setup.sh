#!/bin/zsh

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Make scripts executable
chmod u+x dotfiles.sh
chmod u+x brews.sh
chmod u+x casks.sh
chmod u+x osx.sh

# sync files, install brews and casks
./scripts/dotfiles.sh
./scripts/brew.sh
./scripts/brew-cask.sh
./scripts/osx.sh
