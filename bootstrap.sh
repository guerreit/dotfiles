#!/bin/bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin bash;

function doIt() {
  rsync --exclude ".git/" \
  --exclude ".DS_Store" \
  --exclude ".osx" \
  --exclude "brew.sh" \
  --exclude ".profile" \
  --exclude ".exports" \
  --exclude "brew-cask.sh" \
  --exclude "bootstrap.sh" \
  --exclude "setup.sh" \
  --exclude "README.md" \
  --exclude "LICENSE-MIT.txt" \
  -avh --no-perms . ~;
  source ~/.bashrc;
}

doIt;
unset doIt;
