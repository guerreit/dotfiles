#!/usr/bin/env zsh
set -euo pipefail

REPO_ROOT="$(cd "${0:A:h}/.." && pwd)"
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME" "$SANDBOX/repo"
cp -R "$REPO_ROOT/scripts" "$REPO_ROOT/src" "$SANDBOX/repo/"
ROOT="$HOME/.dotfiles-backup"

mkdir -p "$ROOT/20250101_000000" "$ROOT/20250201_000000" \
  "$ROOT/20250301_000000" "$ROOT/20250101_000000-sync.abcdefgh" \
  "$ROOT/20250201_000000-sync.abcdefgh" "$ROOT/leave-me" "$SANDBOX/outside"
cp "$REPO_ROOT/README.md" "$ROOT/20250101_000000/README.md"
ln -s "$SANDBOX/outside" "$ROOT/20240101_000000"
"$REPO_ROOT/dotfiles" cleanup-backups --keep 1 > /dev/null
[[ -d "$ROOT/20250101_000000" && ! -e "$ROOT/archives" ]]
"$REPO_ROOT/dotfiles" cleanup-backups --keep 1 --apply > /dev/null
[[ ! -e "$ROOT/20250101_000000" && -d "$ROOT/20250301_000000" ]]
[[ -d "$ROOT/20250201_000000-sync.abcdefgh" && -d "$ROOT/leave-me" ]]
[[ -L "$ROOT/20240101_000000" && -d "$SANDBOX/outside" ]]
mkdir "$SANDBOX/restore"
tar -xzf "$ROOT/archives/20250101_000000.tar.gz" -C "$SANDBOX/restore"
cmp "$REPO_ROOT/README.md" "$SANDBOX/restore/20250101_000000/README.md"
"$REPO_ROOT/dotfiles" cleanup-backups --archives --delete --keep 1 --apply > /dev/null
[[ ! -e "$ROOT/archives/20250101_000000.tar.gz" ]]
[[ -f "$ROOT/archives/20250201_000000.tar.gz" ]]
[[ -f "$ROOT/archives/20250101_000000-sync.abcdefgh.tar.gz" ]]
mkdir "$ROOT/20250401_000000"
"$REPO_ROOT/dotfiles" cleanup-backups --delete --keep 1 --apply > /dev/null
[[ ! -e "$ROOT/20250301_000000" && -d "$ROOT/20250401_000000" ]]
for invalid_args in '--keep 0' '--keep -1' '--keep nope' '--archives' '--unknown'; do
  if "$REPO_ROOT/dotfiles" cleanup-backups ${=invalid_args} > /dev/null 2>&1; then
    print -u2 -- "Unexpected success: $invalid_args"
    exit 1
  fi
done
mkdir "$ROOT/20250201_000000"
if "$REPO_ROOT/dotfiles" cleanup-backups --keep 1 --apply > /dev/null 2>&1; then
  print -u2 -- 'Expected an archive collision to fail'
  exit 1
fi
[[ -d "$ROOT/20250201_000000" && ! -e "$ROOT/.cleanup-lock" ]]
mkdir "$ROOT/.cleanup-lock"
if "$REPO_ROOT/dotfiles" cleanup-backups --delete --keep 1 --apply > /dev/null 2>&1; then
  print -u2 -- 'Expected concurrent cleanup to fail'
  exit 1
fi
rmdir "$ROOT/.cleanup-lock"
print 'PASS: preview, retention, archive restoration, deletion, symlinks, collisions and locking'

for profile in personal work; do
  export HOME="$SANDBOX/$profile"
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
  mkdir -p "$HOME"
  git config --file "$HOME/.gitconfig" user.name 'Original Identity'
  git config --file "$HOME/.gitconfig" user.email 'original@example.test'
  zsh "$SANDBOX/repo/scripts/sync.sh" "$profile" > /dev/null
  snapshots=("$HOME/.dotfiles-backup"/*(N/))
  [[ ${#snapshots[@]} -eq 1 ]]
  [[ "$(git config --file "$snapshots[1]/.gitconfig" user.name)" == 'Original Identity' ]]
  cmp "$REPO_ROOT/src/.aliases" "$HOME/.aliases"
  [[ ! -e "$HOME/.gitconfig.roles" ]]
  zsh "$SANDBOX/repo/scripts/sync.sh" > /dev/null
  snapshots=("$HOME/.dotfiles-backup"/*(N/))
  [[ ${#snapshots[@]} -eq 1 ]]
  cp "$REPO_ROOT/README.md" "$HOME/.aliases"
  cp "$REPO_ROOT/README.md" "$HOME/.ssh/config"
  zsh "$SANDBOX/repo/scripts/sync.sh" > /dev/null
  snapshots=("$HOME/.dotfiles-backup"/*(N/))
  [[ ${#snapshots[@]} -eq 2 ]]
  alias_backups=("$HOME/.dotfiles-backup"/*/.aliases(N))
  ssh_backups=("$HOME/.dotfiles-backup"/*/.ssh_config.backup(N))
  [[ ${#alias_backups[@]} -eq 1 && ${#ssh_backups[@]} -eq 1 ]]
  cmp "$REPO_ROOT/README.md" "$alias_backups[1]"
  cmp "$REPO_ROOT/README.md" "$ssh_backups[1]"
  zsh "$SANDBOX/repo/scripts/backup.sh" > /dev/null
  zsh "$SANDBOX/repo/scripts/backup.sh" > /dev/null
  full_snapshots=("$HOME/.dotfiles-backup"/*-snapshot.*(N/))
  [[ ${#full_snapshots[@]} -eq 2 ]]
  cmp "$HOME/.aliases" "$full_snapshots[1]/.aliases"
  cmp "$HOME/.ssh/config" "$full_snapshots[1]/.ssh/config"
  print "PASS: $profile dotfile deployment, original config preservation, no-op sync and full snapshots"
done
