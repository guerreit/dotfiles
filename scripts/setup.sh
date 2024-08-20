#!/bin/zsh

# Install oh-my-zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || { echo "Failed to install oh-my-zsh"; exit 1; }
else
    echo "oh-my-zsh is already installed."
fi

# Make scripts executable
echo "Making scripts executable..."
chmod u+x scripts/brews.sh \
         scripts/casks.sh \
         scripts/osx.sh \
         scripts/sync.sh || { echo "Failed to make scripts executable"; exit 1; }

# Install brews and casks
echo "Running brews.sh..."
./scripts/brews.sh || { echo "brews.sh failed"; exit 1; }

echo "Running casks.sh..."
./scripts/casks.sh || { echo "casks.sh failed"; exit 1; }

# Light OSX manipulation
echo "Running osx.sh..."
./scripts/osx.sh || { echo "osx.sh failed"; exit 1; }

# Sync dotfiles
echo "Syncing dotfiles with sync.sh..."
./scripts/sync.sh || { echo "sync.sh failed"; exit 1; }

echo "Setup complete!"
