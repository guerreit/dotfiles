#!/usr/bin/env zsh
# Backup store tests: naming, layout, classification and restore, including
# the legacy layouts older backups on disk still use.
set -euo pipefail

REPO_ROOT="$(cd "${0:A:h}/.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home"
mkdir -p "$HOME"
umask 077

source "$REPO_ROOT/scripts/backup-store.zsh"
ROOT="$(backup_root)"

fail() { print -u2 -- "FAIL: $*"; exit 1; }
mode() { stat -f '%Lp' "$1"; }

# --- Naming and permissions ---------------------------------------------------------

snap="$(backup_open snapshot)"
sync_backup="$(backup_open sync)"
[[ "${snap:t}" =~ '^[0-9]{8}_[0-9]{6}-snapshot\.[[:alnum:]]{8}$' ]] || fail "snapshot name: ${snap:t}"
[[ "${sync_backup:t}" =~ '^[0-9]{8}_[0-9]{6}-sync\.[[:alnum:]]{8}$' ]] || fail "sync name: ${sync_backup:t}"
[[ "$(mode "$ROOT")" == 700 && "$(mode "$snap")" == 700 ]] || fail "backups must be private"
backup_open weekly 2>/dev/null && fail "unknown kinds are rejected"

# --- Save and close ------------------------------------------------------------------

backup_close "$sync_backup" || fail "an empty backup is removed on close"
[[ ! -e "$sync_backup" ]] || fail "empty backup still exists"

mkdir -p "$HOME/.ssh" "$HOME/.oh-my-zsh/custom/themes"
print 'Host example' > "$HOME/.ssh/config"
print 'theme' > "$HOME/.oh-my-zsh/custom/themes/t.zsh-theme"
backup_save "$snap" .ssh/config
backup_save "$snap" .oh-my-zsh/custom
backup_save "$snap" .missing && fail "saving a missing path returns 1"
[[ -f "$snap/.ssh/config" && -f "$snap/.oh-my-zsh/custom/themes/t.zsh-theme" ]] ||
  fail "files are stored at their home-relative paths"
backup_close "$snap" && fail "a backup with files is kept"
rm -rf "$snap"
print 'PASS: backup naming, permissions, home-relative layout and empty-backup removal'

# --- Classification and listing ------------------------------------------------------

[[ "$(backup_kind "$ROOT/20250101_000000")" == snapshot ]] || fail "legacy name is a snapshot"
[[ "$(backup_kind 20250101_000000-sync.abcdefgh)" == sync ]] || fail "sync name"
[[ "$(backup_kind archives/20250101_000000-snapshot.abcdefgh.tar.gz)" == snapshot ]] || fail "archive name"
for bad in leave-me 20250101 20250101_000000-weekly.abcdefgh 20250101_000000-sync.short; do
  backup_kind "$bad" >/dev/null && fail "not a backup: $bad"
done

mkdir -p "$ROOT/20250201_000000" "$ROOT/20250101_000000-sync.abcdefgh" "$ROOT/leave-me" "$SANDBOX/outside"
ln -s "$SANDBOX/outside" "$ROOT/20240101_000000"
[[ "$(backup_list)" == "$ROOT/20250101_000000-sync.abcdefgh"$'\n'"$ROOT/20250201_000000" ]] ||
  fail "listing skips symlinks and unrecognised entries, oldest first: $(backup_list)"
rm -rf "$ROOT"/*(N) "$ROOT"/.*(N)
print 'PASS: classification and listing of current, legacy and archived backups'

# --- Snapshot coverage -----------------------------------------------------------------

paths="$(backup_snapshot_paths)"
for expected in .zshrc .gitconfig .gitconfig.role-rules .gitconfig.personal .ssh/config .oh-my-zsh/custom; do
  print -r -- "$paths" | grep -qx -- "$expected" || fail "snapshot should cover $expected"
done
for excluded in .gitconfig.roles .ssh_config; do
  print -r -- "$paths" | grep -qx -- "$excluded" && fail "snapshot should not cover repo-only $excluded"
done
print 'PASS: snapshots cover every deployed and generated file'

# --- Round trip ------------------------------------------------------------------------

print 'original zshrc' > "$HOME/.zshrc"
print '[user]' > "$HOME/.gitconfig.role-rules"
snap="$(backup_snapshot)"
[[ -n "$snap" && -f "$snap/.zshrc" && -f "$snap/.gitconfig.role-rules" && -f "$snap/.ssh/config" ]] ||
  fail "snapshot captures managed files"
print 'changed' > "$HOME/.zshrc"
print 'changed' > "$HOME/.ssh/config"
chmod 644 "$HOME/.ssh/config"
backup_restore "$snap" > "$SANDBOX/out"
[[ "$(cat "$HOME/.zshrc")" == 'original zshrc' && "$(cat "$HOME/.ssh/config")" == 'Host example' ]] ||
  fail "restore puts files back"
[[ "$(mode "$HOME/.ssh/config")" == 600 ]] || fail "restored SSH config is 600"
pre=("$ROOT"/*-snapshot.*(N/))
[[ ${#pre[@]} -eq 2 ]] || fail "restore takes a fresh snapshot first"
grep -q 'Skipped Oh My Zsh' "$SANDBOX/out" || fail "Oh My Zsh needs --include-omz"
backup_restore "$SANDBOX/outside" 2>/dev/null && fail "restore refuses folders outside the backup root"
print 'PASS: snapshot and restore round trip'

# --- Legacy layouts (as found in real backups on disk) ----------------------------------

legacy_snap="$ROOT/20250101_000000"
mkdir -p "$legacy_snap/oh-my-zsh/custom/themes"
print 'legacy zshrc' > "$legacy_snap/.zshrc"
print 'legacy theme' > "$legacy_snap/oh-my-zsh/custom/themes/legacy.zsh-theme"
rm -rf "$HOME/.oh-my-zsh"
backup_restore --include-omz "$legacy_snap" > /dev/null
[[ "$(cat "$HOME/.zshrc")" == 'legacy zshrc' ]] || fail "legacy snapshot restores flat files"
[[ "$(cat "$HOME/.oh-my-zsh/custom/themes/legacy.zsh-theme")" == 'legacy theme' ]] ||
  fail "legacy oh-my-zsh/custom restores to ~/.oh-my-zsh/custom"
[[ ! -e "$HOME/oh-my-zsh" ]] || fail "legacy oh-my-zsh must not land in ~/oh-my-zsh"

legacy_sync="$ROOT/20250102_000000-sync.abcdefgh"
mkdir -p "$legacy_sync"
print 'Host legacy' > "$legacy_sync/.ssh_config.backup"
print 'legacy profile' > "$legacy_sync/.profile.backup"
backup_restore "$legacy_sync" > "$SANDBOX/out"
[[ "$(cat "$HOME/.ssh/config")" == 'Host legacy' && "$(mode "$HOME/.ssh/config")" == 600 ]] ||
  fail "legacy .ssh_config.backup restores to ~/.ssh/config"
[[ "$(cat "$HOME/.profile")" == 'legacy profile' && ! -e "$HOME/.profile.backup" ]] ||
  fail "legacy .profile.backup restores to ~/.profile"
grep -q 'Partial backup' "$SANDBOX/out" && grep -q '.profile.backup' "$SANDBOX/out" ||
  fail "restoring a sync backup warns it is partial and lists the files"
print 'PASS: legacy snapshot and sync layouts restore to the right paths'
