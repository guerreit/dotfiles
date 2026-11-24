#!/usr/bin/env zsh
set -euo pipefail

REPO_ROOT="$(cd "${0:A:h}/.." && pwd)"
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME" "$SANDBOX/repo"
cp -R "$REPO_ROOT/scripts" "$REPO_ROOT/src" "$REPO_ROOT/dotfiles" "$SANDBOX/repo/"
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

# The machine-local default role (src/.gitconfig.roles.local) selects the
# default include; sync takes no profile and never edits the repo.
for profile in personal work; do
  export HOME="$SANDBOX/$profile"
  print -r -- "GIT_DEFAULT_ROLE=\"$profile\"" > "$SANDBOX/repo/src/.gitconfig.roles.local"
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
  mkdir -p "$HOME"
  git config --file "$HOME/.gitconfig" user.name 'Original Identity'
  git config --file "$HOME/.gitconfig" user.email 'original@example.test'
  zsh "$SANDBOX/repo/scripts/sync.sh" > /dev/null
  snapshots=("$HOME/.dotfiles-backup"/*(N/))
  [[ ${#snapshots[@]} -eq 1 ]]
  [[ "$(git config --file "$snapshots[1]/.gitconfig" user.name)" == 'Original Identity' ]]
  cmp "$REPO_ROOT/src/.aliases" "$HOME/.aliases"
  cmp "$REPO_ROOT/src/.gitignore_global" "$HOME/.gitignore_global"
  [[ "$(git config --file "$HOME/.gitconfig" core.excludesfile)" == "~/.gitignore_global" ]]
  [[ ! -e "$HOME/.gitconfig.roles" ]]
  [[ "$(git config --file "$HOME/.gitconfig" --get include.path)" == "~/.gitconfig.role-rules" ]]
  [[ -f "$HOME/.gitconfig.role-rules" && -f "$HOME/.gitconfig.personal" && -f "$HOME/.gitconfig.work" ]]
  [[ "$(git config --file "$HOME/.gitconfig.role-rules" --get include.path)" == "~/.gitconfig.$profile" ]]
  [[ ! -e "$HOME/.gitconfig.roles.local" ]]
  # Sync leaves the repo untouched; only the test's own local file differs.
  diff -r --exclude .gitconfig.roles.local "$REPO_ROOT/src" "$SANDBOX/repo/src"
  zsh "$SANDBOX/repo/scripts/sync.sh" > /dev/null
  snapshots=("$HOME/.dotfiles-backup"/*(N/))
  [[ ${#snapshots[@]} -eq 1 ]]
  cp "$REPO_ROOT/README.md" "$HOME/.aliases"
  cp "$REPO_ROOT/README.md" "$HOME/.ssh/config"
  zsh "$SANDBOX/repo/scripts/sync.sh" > /dev/null
  snapshots=("$HOME/.dotfiles-backup"/*(N/))
  [[ ${#snapshots[@]} -eq 2 ]]
  alias_backups=("$HOME/.dotfiles-backup"/*/.aliases(N))
  ssh_backups=("$HOME/.dotfiles-backup"/*-sync.*/.ssh/config(N))
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
rm "$SANDBOX/repo/src/.gitconfig.roles.local"

export HOME="$SANDBOX/profile-arg"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME"
if zsh "$SANDBOX/repo/scripts/sync.sh" work > "$SANDBOX/sync.out" 2>&1; then
  print -u2 -- "Expected sync.sh to reject a profile argument"
  exit 1
fi
grep -q "gitconfig.roles.local" "$SANDBOX/sync.out"
[[ -z "$(ls -A "$HOME")" ]]
print "PASS: sync.sh rejects a profile argument and points at the machine-local default role"

export HOME="$SANDBOX/minimal-roles"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME"
cat > "$SANDBOX/repo/src/.gitconfig.roles" <<'EOF'
GIT_PERSONAL_NAME="Test User"
GIT_PERSONAL_EMAIL="test.personal@example.test"
GIT_WORK_NAME="Test User"
GIT_WORK_EMAIL="test.work@example.test"
GIT_DEFAULT_ROLE="personal"
EOF
zsh "$SANDBOX/repo/scripts/sync.sh" > /dev/null
[[ "$(git config --file "$HOME/.gitconfig.role-rules" --get include.path)" == "~/.gitconfig.personal" ]]
print "PASS: sync.sh handles roles files without owner/pattern arrays"

# A global identity in src/.gitconfig aborts sync before anything changes.
export HOME="$SANDBOX/global-identity"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME"
cp "$SANDBOX/repo/src/.gitconfig" "$SANDBOX/gitconfig.orig"
git config --file "$SANDBOX/repo/src/.gitconfig" user.email 'global@example.test'
if zsh "$SANDBOX/repo/scripts/sync.sh" > /dev/null 2>&1; then
  print -u2 -- "Expected sync.sh to refuse a global identity in src/.gitconfig"
  exit 1
fi
[[ ! -e "$HOME/.gitconfig" ]]
mv "$SANDBOX/gitconfig.orig" "$SANDBOX/repo/src/.gitconfig"
print "PASS: sync.sh refuses a global identity in src/.gitconfig without touching HOME"

export HOME="$SANDBOX/no-roles"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME"
mv "$SANDBOX/repo/src/.gitconfig.roles" "$SANDBOX/repo/src/.gitconfig.roles.bak"
if zsh "$SANDBOX/repo/scripts/git-config-status.sh" > "$SANDBOX/status.out" 2>&1; then
  print -u2 -- "Expected git-config-status.sh to fail without roles file"
  exit 1
fi
grep -q "Missing roles configuration" "$SANDBOX/status.out"
if grep -q "parameter not set" "$SANDBOX/status.out"; then
  print -u2 -- "Unexpected unbound-parameter failure in git-config-status.sh"
  exit 1
fi
mv "$SANDBOX/repo/src/.gitconfig.roles.bak" "$SANDBOX/repo/src/.gitconfig.roles"
print "PASS: git-config-status.sh handles missing roles file without set -u crashes"

export HOME="$SANDBOX/status-home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME"
cat > "$SANDBOX/repo/src/.gitconfig.roles" <<'EOF'
GIT_PERSONAL_NAME="Test User"
GIT_PERSONAL_EMAIL="test.personal@example.test"
GIT_WORK_NAME="Test User"
GIT_WORK_EMAIL="test.work@example.test"
GIT_WORK_GITHUB_OWNERS=("CaseOrg")
GIT_DEFAULT_ROLE="personal"
EOF
zsh "$SANDBOX/repo/scripts/sync.sh" > /dev/null
if ! (cd "$SANDBOX/outside" && zsh "$SANDBOX/repo/scripts/git-config-status.sh" > "$SANDBOX/status.out" 2>&1); then
  print -u2 -- "git-config-status.sh failed outside a repository:"
  cat "$SANDBOX/status.out" >&2
  exit 1
fi
grep -q "Not in a Git repository" "$SANDBOX/status.out"
mkdir -p "$HOME/code/case"
git -C "$HOME/code/case" init -q
git -C "$HOME/code/case" remote add origin "https://github.com/caseorg/x.git"
(cd "$HOME/code/case" && zsh "$SANDBOX/repo/scripts/git-config-status.sh" > "$SANDBOX/status.out" 2>&1) || true
grep -q "only if case is ignored" "$SANDBOX/status.out"
print "PASS: git-config-status.sh runs outside a repository and explains wrong-case owners"

export HOME="$SANDBOX/restore-home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
export DOTFILES_DIR="$SANDBOX/repo"
mkdir -p "$HOME"
zsh "$SANDBOX/repo/scripts/sync.sh" > /dev/null
print "before-restore" > "$HOME/.aliases"
restore_snapshot="$HOME/.dotfiles-backup/20260101_000000-snapshot.zzzzzzzz"
mkdir -p "$restore_snapshot/.ssh"
print "after-restore" > "$restore_snapshot/.aliases"
print "Host github.com" > "$restore_snapshot/.ssh/config"
snapshot_dirs_before=("$HOME/.dotfiles-backup"/*-snapshot.*(N/))
snapshot_count_before=${#snapshot_dirs_before[@]}
zsh -c 'source "$HOME/.functions"; restore-dotfiles "$1"' _ "$restore_snapshot" > /dev/null
[[ "$(cat "$HOME/.aliases")" == "after-restore" ]]
[[ -f "$HOME/.ssh/config" ]]
[[ "$(stat -f '%Mp%Lp' "$HOME/.ssh/config")" == "0600" ]]
snapshot_dirs_after=("$HOME/.dotfiles-backup"/*-snapshot.*(N/))
snapshot_count_after=${#snapshot_dirs_after[@]}
[[ $snapshot_count_after -eq $((snapshot_count_before + 1)) ]]
print "PASS: restore-dotfiles restores dotfiles and creates a pre-restore snapshot"
