#!/bin/zsh

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function doIt() {
  rsync --exclude ".git/" \
  --exclude ".DS_Store" \
  --exclude ".osx" \
  --exclude "brew.sh" \
  --exclude "brew-cask.sh" \
  --exclude "bootstrap.sh" \
  --exclude "README.md" \
  --exclude "LICENSE-MIT.txt" \
  -avh --no-perms . ~;
  source ~/.zshrc;
}

doIt;
unset doIt;
