#!/usr/bin/env zsh
#
# Creates a snapshot: a full restore point of every dotfile this repo manages.
# What a snapshot covers is defined in scripts/backup-store.zsh.
#
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPT_DIR/backup-store.zsh"

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }

umask 077
info "Creating snapshot in $(backup_root)"
snapshot="$(backup_snapshot)"
if [[ -n "$snapshot" ]]; then
  success "Backup complete! Files saved to: $snapshot"
else
  success "No files needed a backup"
fi
