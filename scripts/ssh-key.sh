#!/bin/zsh

# Check if SSH directory exists
if [ ! -d ~/.ssh ]; then
    mkdir ~/.ssh
    chmod 700 ~/.ssh
fi

# Check if SSH key already exists
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key already exists. Exiting."
    exit 1
fi

# Prompt for email address
read -p "Enter your email address: " email

# Generate SSH key
ssh-keygen -t ed25519 -C "$email"

# Check if SSH agent is running
if ! pgrep -x "ssh-agent" > /dev/null; then
    eval "$(ssh-agent -s)"
fi

# Add SSH private key to SSH agent
ssh-add ~/.ssh/id_ed25519

echo "SSH key has been generated and added to SSH agent."
