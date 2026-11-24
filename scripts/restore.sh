#!/usr/bin/env zsh
#
# Restores a backup over $HOME after taking a fresh snapshot.
# Usage: restore.sh [--include-omz] <backup-dir>
#
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPT_DIR/backup-store.zsh"

umask 077
backup_restore "$@"
