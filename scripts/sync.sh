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
    # Check if the file is .secrets and if it already exists in the home directory
    if [[ "$(basename "$file")" == ".secrets" && -e "$ROOT_DIR/.secrets" ]]; then
        echo "File $ROOT_DIR/.secrets already exists, skipping copy."
    else
        # Copy each file to root user directory
        cp -r "$file" "$ROOT_DIR"
        # Echo the name of the file being copied
        echo "Copied $file to $ROOT_DIR"
    fi
done

# Disable dotglob to restore default behavior
shopt -u dotglob

# Print message indicating completion
echo "All files copied from $SRC_DIR to $ROOT_DIR"
