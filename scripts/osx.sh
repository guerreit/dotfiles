#!/bin/zsh

# Turn off animations for new windows
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false

# Turns off smooth scrolling
defaults write -g NSScrollAnimationEnabled -bool false

# Disable the over-the-top focus ring animation
defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false

echo "OSX Updates Complete!"
