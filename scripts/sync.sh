#!/usr/bin/env zsh
set -euo pipefail

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

# Set the source directory
SRC_DIR="src/"

# Get the root user directory
ROOT_DIR="$HOME"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"

info "Syncing dotfiles from $SRC_DIR to $ROOT_DIR"

# Exclude list
EXCLUDES=(--exclude ".DS_Store" --exclude ".git" --exclude ".gitignore")

# Backup existing files
mkdir -p "$BACKUP_DIR"
for file in $SRC_DIR.*(N); do
  base=$(basename "$file")
  if [[ -e "$ROOT_DIR/$base" && "$base" != ".secrets" ]]; then
    info "Backing up $ROOT_DIR/$base to $BACKUP_DIR/$base"
    mv "$ROOT_DIR/$base" "$BACKUP_DIR/$base"
  fi
done

# Use rsync for robust syncing
rsync -avh --no-perms --no-owner --no-group --progress $EXCLUDES "$SRC_DIR" "$ROOT_DIR" || { error "rsync failed"; exit 1; }

success "All files copied from $SRC_DIR to $ROOT_DIR (backup in $BACKUP_DIR)"
