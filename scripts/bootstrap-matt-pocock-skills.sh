#!/usr/bin/env zsh
set -euo pipefail

info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

readonly ROOT_SKILLS_DIR="$HOME/.agents/skills"
readonly SETUP_SKILL_DIR="$ROOT_SKILLS_DIR/setup-matt-pocock-skills"

if [[ -d "$SETUP_SKILL_DIR" ]]; then
  success "Matt Pocock skills are already bootstrapped in $ROOT_SKILLS_DIR."
  exit 0
fi

if ! command -v npx &>/dev/null; then
  error "npx is required to bootstrap Matt Pocock skills. Install Node.js, then rerun setup."
  exit 1
fi

info "Installing Matt Pocock skills into $ROOT_SKILLS_DIR..."
npx --yes skills@latest add mattpocock/skills -g -a copilot --all || {
  error "Failed to bootstrap Matt Pocock skills"
  exit 1
}

if [[ ! -d "$SETUP_SKILL_DIR" ]]; then
  error "Matt Pocock skills did not install as expected. Missing $SETUP_SKILL_DIR"
  exit 1
fi

success "Matt Pocock skills bootstrapped successfully in $ROOT_SKILLS_DIR."
