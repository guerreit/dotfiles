#!/bin/zsh

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Make scripts executable
chmod u+x scripts/brews.sh
chmod u+x scripts/casks.sh
chmod u+x scripts/dotfiles.sh
chmod u+x scripts/osx.sh

# sync files, install brews and casks
./scripts/brews.sh
./scripts/casks.sh
./scripts/dotfiles.sh
./scripts/osx.sh
