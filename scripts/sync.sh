#!/usr/bin/env zsh
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/git-identity.zsh"

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }
warning() { print -P "%F{yellow}[WARNING]%f $1"; }

# Get profile from argument if provided
PROFILE_CHOICE="${1:-}"

# Set the source directory
SRC_DIR="$REPO_ROOT/src/"
ROLES_FILE="$SRC_DIR.gitconfig.roles"

# Get the root user directory
ROOT_DIR="$HOME"
BACKUP_ROOT="$HOME/.dotfiles-backup"

# Warns and returns 1 when git cannot apply role rules.
check_git_version() {
  local support=0
  git_role_rules_support || support=$?
  if (( support == 2 )); then
    error "Git not found. Please install Git."
    return 1
  elif (( support == 1 )); then
    warning "Git version $GIT_VERSION_FOUND detected, but $GIT_ROLE_RULES_MIN_VERSION+ required for remote-based conditional includes"
    warning "Falling back to global configuration. Consider upgrading Git."
    return 1
  fi
}

migrate_legacy_config() {
  local profile_file="$ROOT_DIR/.profile"

  if [[ ! -f "$profile_file" ]]; then
    return 0
  fi

  # Check if .profile contains git config
  if ! grep -q "GIT_AUTHOR" "$profile_file" 2>/dev/null; then
    return 0
  fi

  info "Detecting legacy Git configuration in .profile..."

  # Extract values
  local author_name=$(grep "GIT_AUTHOR_NAME=" "$profile_file" | head -1 | sed 's/.*GIT_AUTHOR_NAME="\(.*\)".*/\1/')
  local personal_email=$(grep 'GIT_AUTHOR_EMAIL=.*@me.com' "$profile_file" | head -1 | sed 's/.*GIT_AUTHOR_EMAIL="\(.*\)".*/\1/')
  local work_email=$(grep 'GIT_AUTHOR_EMAIL=.*@slalom.com' "$profile_file" | head -1 | sed 's/.*GIT_AUTHOR_EMAIL="\(.*\)".*/\1/')

  if [[ -z "$personal_email" ]]; then
    personal_email=$(grep 'PROFILE_TYPE="personal"' -A 5 "$profile_file" | grep "GIT_AUTHOR_EMAIL=" | head -1 | sed 's/.*GIT_AUTHOR_EMAIL="\(.*\)".*/\1/')
  fi

  if [[ -z "$work_email" ]]; then
    work_email=$(grep 'PROFILE_TYPE="work"' -A 5 "$profile_file" | grep "GIT_AUTHOR_EMAIL=" | head -1 | sed 's/.*GIT_AUTHOR_EMAIL="\(.*\)".*/\1/')
  fi

  if [[ -n "$author_name" && -n "$personal_email" ]]; then
    info "Migrating Git configuration from .profile..."

    # Update .gitconfig.roles with extracted values
    if [[ -f "$ROLES_FILE" ]]; then
      sed -i.bak "s/^GIT_PERSONAL_NAME=.*/GIT_PERSONAL_NAME=\"$author_name\"/" "$ROLES_FILE"
      sed -i.bak "s/^GIT_PERSONAL_EMAIL=.*/GIT_PERSONAL_EMAIL=\"$personal_email\"/" "$ROLES_FILE"

      if [[ -n "$work_email" ]]; then
        sed -i.bak "s/^GIT_WORK_NAME=.*/GIT_WORK_NAME=\"$author_name\"/" "$ROLES_FILE"
        sed -i.bak "s/^GIT_WORK_EMAIL=.*/GIT_WORK_EMAIL=\"$work_email\"/" "$ROLES_FILE"
      fi

      rm -f "${ROLES_FILE}.bak"
      success "Migrated Git identities from .profile to .gitconfig.roles"
    fi

    # Backup original .profile
    cp "$profile_file" "$BACKUP_DIR/.profile.backup"

    # Add deprecation notice
    local temp_file=$(mktemp)
    cat > "$temp_file" <<'EOF'
# =============================================================================
# NOTICE: Git configuration has been migrated to src/.gitconfig.roles
# =============================================================================
# The git config logic below is DEPRECATED and no longer used.
# Your Git identities are now managed by:
#   - src/.gitconfig.roles in your dotfiles repo
#   - ~/.gitconfig (auto-generated with conditional includes)
#   - ~/.gitconfig.personal and ~/.gitconfig.work (auto-generated)
#
# To update your Git configuration:
#   1. Edit src/.gitconfig.roles in your dotfiles repo
#   2. Run: ./scripts/sync.sh
#
# Original .profile config preserved below for reference:
# =============================================================================

EOF
    cat "$profile_file" >> "$temp_file"
    mv "$temp_file" "$profile_file"

    info "Added deprecation notice to .profile (backup at $BACKUP_DIR/.profile.backup)"
  fi
}

apply_profile_choice() {
  # Profile-to-role rewrite kept as-is; separating the two is tracked separately.
  if [[ -n "$PROFILE_CHOICE" && -f "$ROLES_FILE" ]]; then
    info "Setting default role to: $PROFILE_CHOICE"
    sed -i.bak "s/^GIT_DEFAULT_ROLE=.*/GIT_DEFAULT_ROLE=\"$PROFILE_CHOICE\"/" "$ROLES_FILE"
    rm -f "${ROLES_FILE}.bak"
  fi
}

# Renders the generated Git config into $STAGE_DIR and checks it parses.
# Nothing in the repo or $HOME is touched, so a failure aborts cleanly.
stage_git_configs() {
  if [[ ! -f "$ROLES_FILE" ]]; then
    warning "Roles file not found at $ROLES_FILE - skipping Git config generation"
    return 0
  fi

  if ! load_git_identity_config "$ROLES_FILE"; then
    error "Failed to load $ROLES_FILE - syntax error detected"
    return 1
  fi

  if git config --file "$SRC_DIR.gitconfig" --get user.name >/dev/null ||
     git config --file "$SRC_DIR.gitconfig" --get user.email >/dev/null; then
    error "src/.gitconfig sets user.name or user.email, which would override every Git role"
    error "Remove them; identities belong in $ROLES_FILE"
    return 1
  fi

  info "Generating Git configuration from $ROLES_FILE..."
  render_git_identity_configs "$STAGE_DIR" || return 1

  local dead
  for dead in "${(f)$(git_identity_dead_patterns)}"; do
    [[ -n "$dead" ]] && warning "Work pattern '$dead' can never match: git compares it with the repository's .git folder. Use '$dead/**'."
  done

  local file
  for file in "$SRC_DIR.gitconfig" "$STAGE_DIR"/.gitconfig.*; do
    if ! git config --file "$file" --list >/dev/null 2>&1; then
      error "Invalid Git config syntax in ${file:t}"
      return 1
    fi
  done

  success "Generated .gitconfig.personal, .gitconfig.work and .gitconfig.role-rules"
}

display_git_status() {
  local personal_email work_email
  personal_email=$(git config --file "$STAGE_DIR/.gitconfig.personal" user.email 2>/dev/null || true)
  work_email=$(git config --file "$STAGE_DIR/.gitconfig.work" user.email 2>/dev/null || true)

  info "Git Configuration Status:"
  echo ""
  echo "  Personal: $personal_email"
  echo "  Work:     $work_email"
  echo "  Default:  ${GIT_DEFAULT_ROLE:-personal}"
  echo ""
  echo "  To check active configuration, run: ./scripts/git-config-status.sh"
  echo "  To customize identities, edit: $ROLES_FILE"
  echo ""
}

info "Syncing dotfiles from $SRC_DIR to $ROOT_DIR"

# Backup destination for changed files
mkdir -p "$BACKUP_ROOT"
chmod 700 "$BACKUP_ROOT"
BACKUP_DIR=$(mktemp -d "$BACKUP_ROOT/$(date +%Y%m%d_%H%M%S)-sync.XXXXXXXX")
STAGE_DIR=$(mktemp -d)
trap 'rmdir "$BACKUP_DIR" 2>/dev/null || true; rm -rf "$STAGE_DIR"' EXIT

GIT_CONFIG_STAGED=false
if check_git_version; then
  migrate_legacy_config
  apply_profile_choice

  if ! stage_git_configs; then
    error "Git configuration generation failed - aborting sync before any file changed"
    error "Please fix $ROLES_FILE and try again"
    exit 1
  fi
  GIT_CONFIG_STAGED=true
else
  warning "Git conditional includes not supported - skipping automatic config generation"
  warning "Your Git configuration will use global settings from .profile"
fi

# Exclude list
EXCLUDES=(--exclude ".DS_Store" --exclude ".git" --exclude ".gitignore" --exclude "/.ssh_config" --exclude "/.gitconfig.roles")

# One rsync deploys hand-written src/ and the staged generated files, so both
# share the checksum compare and the backup folder.
info "Syncing files with rsync (changed files backed up to $BACKUP_DIR)..."
rsync -avhc --backup --backup-dir="$BACKUP_DIR" --no-perms --no-owner --no-group --progress "${EXCLUDES[@]}" "$SRC_DIR" "$STAGE_DIR/" "$ROOT_DIR" || { error "rsync failed"; exit 1; }

# Setup SSH config
if [[ -f "$SRC_DIR.ssh_config" ]]; then
  info "Setting up SSH configuration..."
  mkdir -p "$ROOT_DIR/.ssh"
  chmod 700 "$ROOT_DIR/.ssh"

  if [[ -f "$ROOT_DIR/.ssh/config" ]] && ! cmp -s "$SRC_DIR.ssh_config" "$ROOT_DIR/.ssh/config"; then
    # Backup existing config
    cp "$ROOT_DIR/.ssh/config" "$BACKUP_DIR/.ssh_config.backup"
    info "Backed up existing SSH config to $BACKUP_DIR/.ssh_config.backup"
  fi

  cp "$SRC_DIR.ssh_config" "$ROOT_DIR/.ssh/config"
  chmod 600 "$ROOT_DIR/.ssh/config"
  success "SSH config installed to ~/.ssh/config"
else
  warning "SSH config template not found in $SRC_DIR.ssh_config"
fi

if rmdir "$BACKUP_DIR" 2>/dev/null; then
  success "All files synced; no changed files needed a backup"
else
  success "All files synced (changed files backed up in $BACKUP_DIR)"
fi

if [[ "$GIT_CONFIG_STAGED" == "true" ]]; then
  display_git_status
fi
