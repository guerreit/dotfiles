#!/bin/zsh

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Make scripts executable
chmod u+x scripts/brews.sh
chmod u+x scripts/casks.sh
chmod u+x scripts/osx.sh
chmod u+x scripts/sync.sh

# install brews and casks
./scripts/brews.sh
./scripts/casks.sh

# Light OSX manipulation
./scripts/osx.sh

# sync dotfiles
./scripts/sync.sh
