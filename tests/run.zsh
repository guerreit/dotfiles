#!/usr/bin/env zsh
# Runs every check CI runs. Suites sandbox HOME, so this is safe on a real machine.
set -euo pipefail

REPO_ROOT="$(cd "${0:A:h}/.." && pwd)"
cd "$REPO_ROOT"

for f in dotfiles scripts/*.sh scripts/*.zsh tests/*.zsh; do
  zsh -n "$f"
done
print 'PASS: syntax'

zsh tests/backups.zsh
zsh tests/git-identity.zsh
