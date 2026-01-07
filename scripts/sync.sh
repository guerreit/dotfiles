#!/usr/bin/env zsh
set -euo pipefail

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }
warning() { print -P "%F{yellow}[WARNING]%f $1"; }

# Get profile from argument if provided
PROFILE_CHOICE="${1:-}"

# Set the source directory
SRC_DIR="src/"

# Get the root user directory
ROOT_DIR="$HOME"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"

# Git config generation functions
check_git_version() {
  local version=$(git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
  if [[ -z "$version" ]]; then
    error "Git not found. Please install Git."
    return 1
  fi

  local major=$(echo "$version" | cut -d. -f1)
  local minor=$(echo "$version" | cut -d. -f2)

  if [[ $major -lt 2 ]] || [[ $major -eq 2 && $minor -lt 13 ]]; then
    warning "Git version $version detected, but 2.13+ required for conditional includes"
    warning "Falling back to global configuration. Consider upgrading Git."
    return 1
  fi

  return 0
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
    if [[ -f "$SRC_DIR.gitconfig.roles" ]]; then
      sed -i.bak "s/^GIT_PERSONAL_NAME=.*/GIT_PERSONAL_NAME=\"$author_name\"/" "$SRC_DIR.gitconfig.roles"
      sed -i.bak "s/^GIT_PERSONAL_EMAIL=.*/GIT_PERSONAL_EMAIL=\"$personal_email\"/" "$SRC_DIR.gitconfig.roles"

      if [[ -n "$work_email" ]]; then
        sed -i.bak "s/^GIT_WORK_NAME=.*/GIT_WORK_NAME=\"$author_name\"/" "$SRC_DIR.gitconfig.roles"
        sed -i.bak "s/^GIT_WORK_EMAIL=.*/GIT_WORK_EMAIL=\"$work_email\"/" "$SRC_DIR.gitconfig.roles"
      fi

      rm -f "$SRC_DIR.gitconfig.roles.bak"
      success "Migrated Git identities from .profile to .gitconfig.roles"
    fi

    # Backup original .profile
    cp "$profile_file" "$BACKUP_DIR/.profile.backup"

    # Add deprecation notice
    local temp_file=$(mktemp)
    cat > "$temp_file" <<'EOF'
# =============================================================================
# NOTICE: Git configuration has been migrated to ~/.gitconfig.roles
# =============================================================================
# The git config logic below is DEPRECATED and no longer used.
# Your Git identities are now managed by:
#   - ~/.gitconfig.roles (edit this to update identities)
#   - ~/.gitconfig (auto-generated with conditional includes)
#   - ~/.gitconfig.personal and ~/.gitconfig.work (auto-generated)
#
# To update your Git configuration:
#   1. Edit ~/.gitconfig.roles
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

generate_git_configs() {
  local roles_file="$SRC_DIR.gitconfig.roles"

  # Load or create .gitconfig.roles
  if [[ ! -f "$roles_file" ]]; then
    warning ".gitconfig.roles not found, using template values"
    return 0
  fi

  # Update GIT_DEFAULT_ROLE based on profile choice
  if [[ -n "$PROFILE_CHOICE" ]]; then
    info "Setting default role to: $PROFILE_CHOICE"
    sed -i.bak "s/^GIT_DEFAULT_ROLE=.*/GIT_DEFAULT_ROLE=\"$PROFILE_CHOICE\"/" "$roles_file"
    rm -f "${roles_file}.bak"
  fi

  info "Generating Git configuration files from .gitconfig.roles..."

  # Source the roles configuration
  if ! source "$roles_file" 2>/dev/null; then
    error "Failed to load .gitconfig.roles - syntax error detected"
    error "Please check the file syntax and try again"
    return 1
  fi

  # Validate required variables
  if [[ -z "${GIT_PERSONAL_NAME:-}" || -z "${GIT_PERSONAL_EMAIL:-}" ]]; then
    error "GIT_PERSONAL_NAME and GIT_PERSONAL_EMAIL must be set in .gitconfig.roles"
    return 1
  fi

  if [[ -z "${GIT_WORK_NAME:-}" || -z "${GIT_WORK_EMAIL:-}" ]]; then
    error "GIT_WORK_NAME and GIT_WORK_EMAIL must be set in .gitconfig.roles"
    return 1
  fi

  # Generate .gitconfig.personal
  cat > "$SRC_DIR.gitconfig.personal" <<EOF
# ~/.gitconfig.personal - Personal Git Identity
# ==============================================
# This file is automatically generated by sync.sh from .gitconfig.roles
# Do not edit directly - changes will be overwritten
# To update your personal identity, edit ~/.gitconfig.roles and run sync.sh

[user]
	name = $GIT_PERSONAL_NAME
	email = $GIT_PERSONAL_EMAIL
EOF

  # Generate .gitconfig.work
  cat > "$SRC_DIR.gitconfig.work" <<EOF
# ~/.gitconfig.work - Work Git Identity
# ======================================
# This file is automatically generated by sync.sh from .gitconfig.roles
# Do not edit directly - changes will be overwritten
# To update your work identity, edit ~/.gitconfig.roles and run sync.sh

[user]
	name = $GIT_WORK_NAME
	email = $GIT_WORK_EMAIL
EOF

  # Generate main .gitconfig with conditional includes
  local base_gitconfig="$SRC_DIR.gitconfig"
  local temp_gitconfig=$(mktemp)

  # Copy existing .gitconfig content up to any existing includeIf sections
  if [[ -f "$base_gitconfig" ]]; then
    # Remove any existing includeIf or include sections at the end
    sed '/^# Role-based configuration/,$d' "$base_gitconfig" > "$temp_gitconfig"
  else
    error ".gitconfig template not found at $base_gitconfig"
    return 1
  fi

  # Add role-based configuration section
  cat >> "$temp_gitconfig" <<'EOF'

# =============================================================================
# Role-based Configuration (Automatic Git Identity Switching)
# =============================================================================
# WARNING: This section is automatically generated by sync.sh
# Do not edit manually - changes will be overwritten
# To customize your Git identities and directory patterns:
#   1. Edit ~/.gitconfig.roles
#   2. Run: ./scripts/sync.sh
#
# How it works:
# - Work patterns are checked first (includeIf directives)
# - If no work pattern matches, personal config is used (default include)
# - Git automatically selects the right identity based on repository location
# =============================================================================

EOF

  # Add includeIf directives for work patterns
  if [[ -n "${GIT_WORK_PATTERNS:-}" ]]; then
    echo "# Work directory patterns" >> "$temp_gitconfig"
    for pattern in "${GIT_WORK_PATTERNS[@]}"; do
      # Expand ~ to home directory for gitdir (Git requires absolute paths)
      local expanded_pattern="${pattern/#\~/$HOME}"
      # Add trailing slash if pattern ends with /** to ensure proper matching
      if [[ "$expanded_pattern" == *"/**" ]]; then
        expanded_pattern="${expanded_pattern%/**}/"
      fi
      echo "[includeIf \"gitdir:$expanded_pattern\"]" >> "$temp_gitconfig"
      echo "	path = ~/.gitconfig.work" >> "$temp_gitconfig"
    done
    echo "" >> "$temp_gitconfig"
  fi

  # Add default include based on GIT_DEFAULT_ROLE
  local default_role="${GIT_DEFAULT_ROLE:-personal}"
  if [[ "$default_role" == "work" ]]; then
    cat >> "$temp_gitconfig" <<'EOF'
# Default to work configuration
[include]
	path = ~/.gitconfig.work
EOF
  else
    cat >> "$temp_gitconfig" <<'EOF'
# Default to personal configuration
[include]
	path = ~/.gitconfig.personal
EOF
  fi

  mv "$temp_gitconfig" "$base_gitconfig"
  success "Generated .gitconfig with conditional includes"
  success "Generated .gitconfig.personal and .gitconfig.work"
}

determine_profile() {
  # Determine active profile with priority: argument > file > default
  local profile="${PROFILE_CHOICE:-${GIT_DEFAULT_ROLE:-personal}}"
  echo "$profile"
}

set_git_global_config() {
  # Remove any existing global user.name and user.email settings
  # These will be managed by the conditional includes in .gitconfig
  info "Removing global user.name and user.email (managed by conditional includes)..."

  git config --global --unset user.name 2>/dev/null || true
  git config --global --unset user.email 2>/dev/null || true

  local profile=$(determine_profile)
  success "Git identity will be automatically selected based on repository location"
  success "Default role: $profile"

  return 0
}

validate_git_config() {
  info "Validating generated Git configuration..."

  # Test if generated configs are valid
  local test_dir=$(mktemp -d)
  cp "$SRC_DIR.gitconfig" "$test_dir/.gitconfig"
  cp "$SRC_DIR.gitconfig.personal" "$test_dir/.gitconfig.personal" 2>/dev/null || true
  cp "$SRC_DIR.gitconfig.work" "$test_dir/.gitconfig.work" 2>/dev/null || true

  if ! GIT_CONFIG_GLOBAL="$test_dir/.gitconfig" git config --list >/dev/null 2>&1; then
    error "Generated .gitconfig has invalid syntax"
    rm -rf "$test_dir"
    return 1
  fi

  rm -rf "$test_dir"
  success "Git configuration validation passed"
  return 0
}

display_git_status() {
  info "Git Configuration Status:"

  local personal_email=$(grep "email = " "$SRC_DIR.gitconfig.personal" 2>/dev/null | head -1 | sed 's/.*email = //')
  local work_email=$(grep "email = " "$SRC_DIR.gitconfig.work" 2>/dev/null | head -1 | sed 's/.*email = //')

  echo ""
  echo "  Personal: $personal_email"
  echo "  Work:     $work_email"
  echo ""
  echo "  To check active configuration, run: ./scripts/git-config-status.sh"
  echo "  To customize identities, edit: ~/.gitconfig.roles"
  echo ""
}

info "Syncing dotfiles from $SRC_DIR to $ROOT_DIR"

# Backup existing files first
mkdir -p "$BACKUP_DIR"
for file in $SRC_DIR.*(N); do
  base=$(basename "$file")
  if [[ -e "$ROOT_DIR/$base" && "$base" != ".secrets" ]]; then
    info "Backing up $ROOT_DIR/$base to $BACKUP_DIR/$base"
    mv "$ROOT_DIR/$base" "$BACKUP_DIR/$base"
  fi
done

# Check Git version and generate configs if supported
if check_git_version; then
  # Migrate legacy configuration if present
  migrate_legacy_config

  # Generate Git configuration files
  if generate_git_configs; then
    # Validate generated configs
    if ! validate_git_config; then
      error "Git configuration validation failed - aborting sync"
      error "Please fix .gitconfig.roles and try again"
      exit 1
    fi

    # Set global Git config based on profile
    if ! set_git_global_config; then
      error "Failed to set Git global configuration"
      exit 1
    fi
  else
    error "Failed to generate Git configuration files"
    exit 1
  fi
else
  warning "Git conditional includes not supported - skipping automatic config generation"
  warning "Your Git configuration will use global settings from .profile"
fi

# Exclude list
EXCLUDES=(--exclude ".DS_Store" --exclude ".git" --exclude ".gitignore" --exclude ".ssh_config")

# Use rsync for robust syncing
rsync -avh --no-perms --no-owner --no-group --progress $EXCLUDES "$SRC_DIR" "$ROOT_DIR" || { error "rsync failed"; exit 1; }

# Setup SSH config
if [[ -f "$SRC_DIR.ssh_config" ]]; then
  info "Setting up SSH configuration..."
  mkdir -p "$ROOT_DIR/.ssh"
  chmod 700 "$ROOT_DIR/.ssh"

  if [[ -f "$ROOT_DIR/.ssh/config" ]]; then
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

success "All files copied from $SRC_DIR to $ROOT_DIR (backup in $BACKUP_DIR)"

# Display Git configuration status
if check_git_version >/dev/null 2>&1; then
  display_git_status
fi
