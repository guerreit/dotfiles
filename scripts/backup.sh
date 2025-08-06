#!/bin/zsh
set -euo pipefail

# Color functions
info() { echo "[INFO] $1"; }
success() { echo "[SUCCESS] $1"; }
error() { echo "[ERROR] $1" >&2; }

# Create backup directory with timestamp
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

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
  if [ -f "$HOME/$file" ]; then
    cp "$HOME/$file" "$BACKUP_DIR/"
    info "Backed up $file"
    backup_count=$((backup_count + 1))
  fi
done

if [ $backup_count -eq 0 ]; then
  info "No existing dotfiles found to backup"
else
  success "Backed up $backup_count dotfiles to $BACKUP_DIR"
fi

# Also backup any custom Oh My Zsh customizations
if [ -d "$HOME/.oh-my-zsh/custom" ]; then
  mkdir -p "$BACKUP_DIR/oh-my-zsh"
  cp -r "$HOME/.oh-my-zsh/custom" "$BACKUP_DIR/oh-my-zsh/"
  info "Backed up Oh My Zsh customizations"
fi

success "Backup complete! Files saved to: $BACKUP_DIR"
