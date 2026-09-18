#!/usr/bin/env zsh
set -euo pipefail

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

KEEP=5
ACTION=archive
APPLY=false
ARCHIVES=false
BACKUP_ROOT="$HOME/.dotfiles-backup"
TEMP_ARCHIVE=""
LOCK_DIR=""

usage() {
  print -r -- 'Usage: cleanup-backups.sh [--keep N] [--archive|--delete] [--archives] [--apply|--dry-run]
Preview by default. Keep the newest N backups of each kind (snapshot/sync).
--archive   Compress older directories, verify, then remove originals (default).
--delete    Permanently remove older backups.
--archives  Target archived backups instead of directories; requires --delete.
--apply     Perform the listed action. Without this, nothing changes.
--keep N    Keep at least N of each kind; positive integer, default 5.
Only recognized timestamped backups inside ~/.dotfiles-backup are eligible.'
}

while (( $# > 0 )); do
  case "$1" in
    --keep)
      [[ $# -ge 2 && "$2" == <1-> ]] || { error '--keep requires a positive integer'; exit 1; }
      KEEP="$2"
      shift
      ;;
    --archive) ACTION=archive ;;
    --delete) ACTION=delete ;;
    --archives) ARCHIVES=true ;;
    --apply) APPLY=true ;;
    --dry-run) APPLY=false ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

if [[ "$ARCHIVES" == true && "$ACTION" != delete ]]; then
  error '--archives requires --delete'
  exit 1
fi
if [[ -L "$BACKUP_ROOT" || -L "$BACKUP_ROOT/archives" ]]; then
  error 'Refusing to manage a symlinked backup or archive directory'
  exit 1
fi
if [[ ! -d "$BACKUP_ROOT" ]]; then
  info "No backup directory at $BACKUP_ROOT"
  exit 0
fi

finish() {
  [[ -z "$TEMP_ARCHIVE" ]] || rm -f -- "$TEMP_ARCHIVE"
  [[ -z "$LOCK_DIR" ]] || rmdir "$LOCK_DIR"
  return 0
}

if [[ "$APPLY" == true ]]; then
  umask 077
  if ! mkdir "$BACKUP_ROOT/.cleanup-lock" 2>/dev/null; then
    error 'Cleanup is already running or .cleanup-lock needs inspection'
    exit 1
  fi
  LOCK_DIR="$BACKUP_ROOT/.cleanup-lock"
  trap finish EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
fi

declare -a candidates=() selected=()
typeset -A counts=(snapshot 0 sync 0)
search_dir="$BACKUP_ROOT"
[[ "$ARCHIVES" != true ]] || search_dir="$BACKUP_ROOT/archives"
for candidate in "$search_dir"/*(N); do
  [[ ! -L "$candidate" ]] || continue
  backup_name="${candidate:t}"
  if [[ "$ARCHIVES" == true ]]; then
    [[ -f "$candidate" && "$backup_name" == *.tar.gz ]] || continue
    backup_name="${backup_name%.tar.gz}"
  else
    [[ -d "$candidate" ]] || continue
  fi
  if [[ "$backup_name" =~ '^[0-9]{8}_[0-9]{6}(-(sync|snapshot)\.[[:alnum:]]{8})?$' ]]; then
    candidates+=("$candidate")
  fi
done

for candidate in "${(@On)candidates}"; do
  kind=snapshot
  [[ "${candidate:t}" != *-sync.* ]] || kind=sync
  counts[$kind]=$(( ${counts[$kind]} + 1 ))
  if (( ${counts[$kind]} > KEEP )); then
    selected+=("$candidate")
  fi
done

info "Keeping newest $KEEP of each kind; ${#selected[@]} eligible for $ACTION"
for candidate in "${selected[@]}"; do
  print -r -- "$ACTION: $candidate"
  [[ "$APPLY" == true ]] || continue
  if [[ "$ACTION" == archive ]]; then
    mkdir -p "$BACKUP_ROOT/archives"
    chmod 700 "$BACKUP_ROOT/archives"
    archive="$BACKUP_ROOT/archives/${candidate:t}.tar.gz"
    if [[ -e "$archive" || -L "$archive" ]]; then
      error "Archive already exists; leaving original untouched: $archive"
      exit 1
    fi
    TEMP_ARCHIVE=$(mktemp "$BACKUP_ROOT/archives/.pending.XXXXXXXX")
    tar -czf "$TEMP_ARCHIVE" -C "$BACKUP_ROOT" "${candidate:t}"
    gzip -t "$TEMP_ARCHIVE"
    tar -tzf "$TEMP_ARCHIVE" > /dev/null
    mv "$TEMP_ARCHIVE" "$archive"
    TEMP_ARCHIVE=""
  fi
  rm -rf -- "$candidate"
done

if [[ "$APPLY" == true ]]; then
  success "Processed ${#selected[@]} backups"
else
  info 'Preview only. Add --apply to execute; --delete permanently removes data.'
fi
