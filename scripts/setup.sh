#!/bin/zsh

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Make scripts executable
chmod u+x bootstrap.sh
chmod u+x brew.sh
chmod u+x brew-cask.sh
chmod u+x osx.sh

# sync files, install brews and casks
./scripts/bootstrap.sh
./scripts/brew.sh
./scripts/brew-cask.sh
./scripts/osx.sh
