#!/bin/bash

# Set the source directory
SRC_DIR="src/"

# Get the root user directory
ROOT_DIR="$HOME"

# Enable dotglob to include hidden files
shopt -s dotglob

# Loop through files in source directory
for file in "$SRC_DIR"*
do
    # Copy each file to root user directory
    cp -r "$file" "$ROOT_DIR"
    # Echo the name of the file being copied
    echo "Copied $file to $ROOT_DIR"
done

# Disable dotglob to restore default behavior
shopt -u dotglob

# Print message indicating completion
echo "Files copied from $SRC_DIR to $ROOT_DIR"
