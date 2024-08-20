#!/bin/zsh

# Upgrade all installed casks
brew upgrade --cask || { echo "brew upgrade --cask failed"; exit 1; }

# Install required casks
brew install --cask \
    drawio \
    microsoft-auto-update \
    microsoft-edge \
    microsoft-onenote \
    microsoft-teams \
    postman \
    slack \
    visual-studio-code \
    zoom || { echo "Cask installation failed"; exit 1; }

echo "Casks Installed!"
