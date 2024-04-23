#!/bin/zsh

# Pull latest changes from git
cd "$(dirname "${BASH_SOURCE}")";

# for each file in src, copy it to ~/
for src in src/*; do
  dest="$HOME/.$(basename $src)"
  cp -r $src $dest
done
