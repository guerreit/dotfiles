#!/usr/bin/env zsh
set -euo pipefail

# Color functions
info() { echo "[INFO] $1"; }
success() { echo "[SUCCESS] $1"; }
error() { echo "[ERROR] $1" >&2; }

# Create backup directory with timestamp
umask 077
mkdir -p "$HOME/.dotfiles-backup"
chmod 700 "$HOME/.dotfiles-backup"
BACKUP_DIR=$(mktemp -d "$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)-snapshot.XXXXXXXX")

info "Creating backup in $BACKUP_DIR"

# List of dotfiles to backup
DOTFILES=(
  .zshrc
  .aliases
  .exports
  .functions
  .path
  .profile
  .secrets
  .gitconfig
  .gitconfig.personal
  .gitconfig.work
  .gitattributes
  .gitignore
  .vimrc
  .editorconfig
  .hushlogin
  .stCommitMsg
)

# Backup existing dotfiles
backup_count=0
for file in "${DOTFILES[@]}"; do
  if [[ -f "$HOME/$file" ]]; then
    cp "$HOME/$file" "$BACKUP_DIR/"
    info "Backed up $file"
    backup_count=$((backup_count + 1))
  fi
done

if [[ $backup_count -eq 0 ]]; then
  info "No existing dotfiles found to backup"
else
  success "Backed up $backup_count dotfiles to $BACKUP_DIR"
fi

# Also backup any custom Oh My Zsh customizations
if [[ -f "$HOME/.ssh/config" ]]; then
  mkdir -p "$BACKUP_DIR/.ssh"
  cp -p "$HOME/.ssh/config" "$BACKUP_DIR/.ssh/"
  info "Backed up SSH configuration"
fi

if [[ -d "$HOME/.oh-my-zsh/custom" ]]; then
  mkdir -p "$BACKUP_DIR/oh-my-zsh"
  cp -r "$HOME/.oh-my-zsh/custom" "$BACKUP_DIR/oh-my-zsh/"
  info "Backed up Oh My Zsh customizations"
fi

if rmdir "$BACKUP_DIR" 2>/dev/null; then
  success "No files needed a backup"
else
  success "Backup complete! Files saved to: $BACKUP_DIR"
fi
