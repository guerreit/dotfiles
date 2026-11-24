#!/usr/bin/env zsh
#
# Backup store: the one module that knows how backups are named, laid out,
# recognised and restored.
#
#   backup_open <kind>                     create a backup, print its path
#   backup_save <backup> <home-path>       copy ~/<home-path> into it
#   backup_close <backup>                  drop it if nothing was saved
#   backup_snapshot                        full restore point of everything managed
#   backup_kind <backup>                   print snapshot | sync
#   backup_list [archives]                 print recognised backups, oldest first
#   backup_restore [--include-omz] <dir>   restore a backup over $HOME
#
# Layout: every backup stores files at their path relative to $HOME, so a
# restore is "copy the tree back". Names: <YYYYmmdd_HHMMSS>-<kind>.<id>.
# Kinds:
#   snapshot  full restore point (legacy: bare <YYYYmmdd_HHMMSS>)
#   sync      only the files a change was about to overwrite

typeset -g BACKUP_STORE_REPO_ROOT="${${(%):-%x}:A:h:h}"

backup_root() {
  print -r -- "$HOME/.dotfiles-backup"
}

# Args: $1 - snapshot | sync
# Prints the new backup's path. The root and backup are private (700).
backup_open() {
  local kind="$1" root
  [[ "$kind" == snapshot || "$kind" == sync ]] || { print -u2 -- "Unknown backup kind: $kind"; return 1; }
  root="$(backup_root)"
  mkdir -p "$root"
  chmod 700 "$root"
  mktemp -d "$root/$(date +%Y%m%d_%H%M%S)-$kind.XXXXXXXX"
}

# Copies ~/<home-path> (file or folder) into the backup at the same path.
# Returns 1 if there is nothing at that path.
backup_save() {
  local backup="$1" rel="$2"
  [[ -e "$HOME/$rel" || -L "$HOME/$rel" ]] || return 1
  mkdir -p "$backup/${rel:h}"
  if [[ -d "$HOME/$rel" ]]; then
    cp -Rp "$HOME/$rel" "$backup/${rel:h}/"
  else
    cp -p "$HOME/$rel" "$backup/$rel"
  fi
}

# Removes the backup if nothing was saved into it.
# Returns 0 if it was empty and removed, 1 if it holds files and was kept.
backup_close() {
  rmdir "$1" 2>/dev/null
}

# Home-relative paths a snapshot covers: everything sync deploys from src/,
# the generated Git config, and machine-local state sync touches.
backup_snapshot_paths() {
  local src="$BACKUP_STORE_REPO_ROOT/src" file rel
  for file in "$src"/**/*(D.N); do
    rel="${file#$src/}"
    case "$rel" in
      .gitconfig.roles|.gitconfig.roles.local|.ssh_config|.DS_Store|*/.DS_Store|.gitignore|.oh-my-zsh/custom/*) continue ;;
    esac
    print -r -- "$rel"
  done
  print -rl -- .gitconfig.personal .gitconfig.work .gitconfig.role-rules \
    .secrets .ssh/config .oh-my-zsh/custom
}

# Creates a snapshot of every managed path that exists. Prints its path, or
# nothing if there was nothing to back up.
backup_snapshot() {
  local backup rel
  backup="$(backup_open snapshot)" || return 1
  for rel in "${(@uf)$(backup_snapshot_paths)}"; do
    backup_save "$backup" "$rel" || true
  done
  backup_close "$backup" || print -r -- "$backup"
}

# Prints the kind of a backup folder or archive; returns 1 if the name is not
# a recognised backup.
backup_kind() {
  local name="${1:t}"
  name="${name%.tar.gz}"
  [[ "$name" =~ '^[0-9]{8}_[0-9]{6}(-(sync|snapshot)\.[[:alnum:]]{8})?$' ]] || return 1
  if [[ "$name" == *-sync.* ]]; then
    print -r -- sync
  else
    print -r -- snapshot
  fi
}

# Prints recognised backups, oldest first. Symlinks and unrecognised entries
# are never listed.
# Args: $1 - "archives" to list compressed backups instead of folders
backup_list() {
  local root entry
  root="$(backup_root)"
  if [[ "${1:-}" == archives ]]; then
    for entry in "$root/archives"/*.tar.gz(N.); do
      backup_kind "$entry" >/dev/null && print -r -- "$entry"
    done
  else
    for entry in "$root"/*(N/); do
      [[ -L "$entry" ]] && continue
      backup_kind "$entry" >/dev/null && print -r -- "$entry"
    done
  fi
  return 0
}

# Restores a backup over $HOME after taking a fresh snapshot. Legacy layouts
# are translated: oh-my-zsh/custom -> .oh-my-zsh/custom,
# .ssh_config.backup -> .ssh/config, .profile.backup -> .profile.
# Oh My Zsh files are restored only with --include-omz.
backup_restore() {
  local include_omz=false
  if [[ "${1:-}" == "--include-omz" ]]; then
    include_omz=true
    shift
  fi

  local restore_dir="${1:-}" root kind item base pre_restore
  if [[ -z "$restore_dir" ]]; then
    print -u2 -- "Usage: restore [--include-omz] <backup-dir>"
    return 1
  fi

  root="$(backup_root)"
  restore_dir="${restore_dir:A}"
  if [[ ! -d "$restore_dir" ]]; then
    print -u2 -- "✗ Backup directory does not exist: $restore_dir"
    return 1
  fi
  if [[ "$restore_dir" != "${root:A}"/* ]]; then
    print -u2 -- "✗ Refusing to restore outside $root: $restore_dir"
    return 1
  fi

  kind="$(backup_kind "$restore_dir")" || kind=unknown
  if [[ "$kind" == sync ]]; then
    print -r -- "Partial backup: a sync backup only holds the files a change overwrote. Restoring:"
    (cd "$restore_dir" && print -rl -- **/*(D.N) | sed 's/^/  /')
  fi

  pre_restore="$(backup_snapshot)" || return 1
  [[ -n "$pre_restore" ]] && print -r -- "Saved current state to $pre_restore"

  for item in "$restore_dir"/*(DN); do
    base="${item:t}"
    case "$base" in
      .ssh|.ssh_config.backup)
        ;; # handled below so permissions are always set
      .profile.backup)
        cp -p "$item" "$HOME/.profile"
        ;;
      oh-my-zsh|.oh-my-zsh)
        if [[ "$include_omz" == true ]]; then
          # Both layouts hold custom/ directly inside, so the contents merge
          # into ~/.oh-my-zsh the same way.
          mkdir -p "$HOME/.oh-my-zsh"
          cp -Rp "$item"/. "$HOME/.oh-my-zsh/"
        else
          print -r -- "Skipped Oh My Zsh files (add --include-omz to restore them)"
        fi
        ;;
      *)
        cp -Rp "$item" "$HOME/"
        ;;
    esac
  done

  local ssh_source=""
  if [[ -f "$restore_dir/.ssh/config" ]]; then
    ssh_source="$restore_dir/.ssh/config"
  elif [[ -f "$restore_dir/.ssh_config.backup" ]]; then
    ssh_source="$restore_dir/.ssh_config.backup"
  fi
  if [[ -n "$ssh_source" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    cp -p "$ssh_source" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
  fi

  print -r -- "✓ Restored $kind backup from $restore_dir"
}
