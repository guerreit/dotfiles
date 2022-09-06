#!/bin/bash

# Install oh-my-bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Make scripts executable
chmod u+x bootstrap.sh
chmod u+x brew.sh
chmod u+x brew-cask.sh

./bootstrap.sh
./brew.sh
./brew-cask.sh
