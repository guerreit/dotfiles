# Copilot Instructions for Dotfiles

## Architecture Overview

This is a **role-aware macOS dotfiles system** that maintains separate Git identities (personal/work) with automatic switching based on directory patterns. The architecture comprises three layers:

1. **Source Layer** (`src/`): Version-controlled dotfile templates including `.gitconfig.roles` (single source of truth for Git identities)
2. **Script Layer** (`scripts/`): Orchestration scripts that install, backup, sync, and validate configurations
3. **Deployment Layer** (`$HOME`): Generated configs deployed via rsync with automatic backups

**Key Innovation**: Git identity is determined by matching the current directory against glob patterns in `src/.gitconfig.roles`, which generates conditional includes in `.gitconfig`.

## Critical Workflows

### Installation Flow (scripts/setup.sh)

```
Profile Selection → Persist to .gitconfig.roles → Optional SSH Keys → Backup →
Install Plugins → Install Brews/Casks → Apply macOS Tweaks → Sync → Validate
```

Profile choice (personal/work) drives package installation AND updates `GIT_DEFAULT_ROLE` in `.gitconfig.roles`.

### Sync Flow (scripts/sync.sh)

```
Load .gitconfig.roles → Generate .gitconfig* files → Validate →
rsync src/ to $HOME (with exclusions) → Set SSH config permissions
```

**Critical**: `sync.sh` is idempotent and must be run after editing ANY file in `src/`. It generates:

- `~/.gitconfig` with conditional includes
- `~/.gitconfig.personal` and `~/.gitconfig.work`
- Removes global `user.name`/`user.email` to ensure conditional includes work

### Validation (scripts/git-config-status.sh)

Detects active Git identity by matching current directory against `GIT_WORK_PATTERNS`, shows expected vs actual identity, and validates all config files exist.

## Project-Specific Conventions

### Shell Scripting (Follows AGENTS.md)

- **Shebang**: Always `#!/usr/bin/env zsh` for portability
- **Strict mode**: `set -euo pipefail` at top of every script
- **Color functions**: Use `info()`, `success()`, `error()`, `warning()` defined in each script via print -P with colors
- **Quoting**: Always quote variables: `"$variable"`, use `"${variable}"` in complex strings
- **Tests**: Use `[[ ]]` for conditionals, never `[ ]`
- **Arrays**: `declare -a array=(...)` and iterate with `"${array[@]}"`

### Git Identity Management

- **Source of truth**: `src/.gitconfig.roles` contains all identity data and directory patterns
- **Pattern matching**: Use `GIT_WORK_PATTERNS` array with glob patterns (supports `**` for recursive)
- **Migration logic**: `sync.sh` includes `migrate_legacy_config()` to upgrade from old `.profile`-based config
- **No global identity**: `sync.sh` explicitly removes `user.name` and `user.email` from `~/.gitconfig` to force conditional includes

### Profile vs Role (Critical Distinction)

- **Profile** (personal/work): Installation-time choice that determines which packages/apps get installed
- **Role** (personal/work): Runtime Git identity based on directory location
- `setup.sh` syncs these by updating `GIT_DEFAULT_ROLE`, but they can diverge if user re-edits `.gitconfig.roles`

### Backup Strategy

- **Pre-install**: `backup.sh` creates `~/.dotfiles-backup/<timestamp>` before setup
- **Per-sync**: `sync.sh` moves existing files to `~/.dotfiles_backup_<timestamp>` before overwriting
- Never delete existing configs—always backup first

### File Sync Exclusions

When syncing `src/` to `$HOME`, `sync.sh` excludes:

- `.DS_Store`, `.git`, `.gitignore` (system files)
- `.ssh_config` (handled separately with chmod 600)
- `.gitconfig.roles` (stays in src/, generates configs but isn't deployed)

### SSH Configuration

- Keys generated via `ssh-key.sh`: two Ed25519 keys (personal/work)
- `src/.ssh_config` → `~/.ssh/config` with strict permissions (chmod 600)
- Keys added to ssh-agent and macOS keychain automatically

### Package Management

- Common packages in `COMMON_BREWS`/`COMMON_CASKS` arrays
- Profile-specific packages in `PROFILE_BREWS`/`PROFILE_CASKS`
- Check if already installed before attempting install: `brew list --formula | grep -q "^$pkg$"`

## Key Files & Their Purpose

- `src/.gitconfig.roles`: Master config defining identities, patterns, default role (NEVER deployed to $HOME)
- `scripts/setup.sh`: Main orchestrator, runs once to bootstrap entire system
- `scripts/sync.sh`: Idempotent syncer, regenerates Git configs and deploys dotfiles (run after any src/ edit)
- `scripts/git-config-status.sh`: Diagnostic tool showing active identity and pattern matches
- `scripts/backup.sh`: Manual backup utility (also called by setup.sh)

## Development Guidelines

### Adding New Scripts

1. Start with template from AGENTS.md (shebang, strict mode, color functions)
2. Make executable: `chmod u+x scripts/new-script.sh`
3. Add to `setup.sh` orchestration if needed at install time
4. Document in README.md under "What setup.sh Runs" or "Supporting Scripts"

### Modifying Git Identity Logic

1. Edit `src/.gitconfig.roles` for identity changes or new patterns
2. Modify `generate_git_configs()` function in `sync.sh` for structural changes
3. Update `git-config-status.sh` if detection logic changes
4. Test with `--dry-run` flag before deploying

### Adding Profile-Specific Packages

1. Edit `scripts/brews.sh` or `scripts/casks.sh`
2. Add to appropriate array based on profile condition: `if [[ "$DOTFILES_PROFILE" == "work" ]]`
3. Check if package exists before installing to maintain idempotency

### Testing Changes

1. Never test directly in production $HOME—use VM or container
2. Verify scripts pass: `zsh -n script.sh` (syntax check)
3. For debugging: `zsh -x script.sh` or add `set -x` below strict mode
4. Test both profiles (personal/work) if touching profile-conditional code
5. Validate Git identity with: `./scripts/git-config-status.sh --dry-run`

## Common Pitfalls

1. **Editing $HOME configs directly**: Always edit in `src/` then run `sync.sh`
2. **Forgetting to sync**: After editing `src/.gitconfig.roles`, MUST run `sync.sh` to regenerate configs
3. **Unquoted variables**: Shell expansion bugs—always quote: `"$variable"`
4. **Global Git identity**: If `user.name` exists in global `~/.gitconfig`, conditional includes won't work
5. **SSH config permissions**: Must be 600 or SSH will reject the config file
6. **Array syntax**: Zsh arrays are 1-indexed, use `"${array[@]}"` for all elements
7. **Profile environment**: Child scripts depend on `$DOTFILES_PROFILE` being exported by `setup.sh`

## External Dependencies

- **Homebrew**: Must be pre-installed (setup.sh checks with `command -v brew`)
- **Oh My Zsh**: Installed by `scripts/plugins.sh`, not assumed to exist
- **VS Code CLI**: `code` command must be in PATH for extension installs (failure is graceful)
- **Git 2.13+**: Required for conditional includes (sync.sh checks version and warns)

## Reference Implementation

For shell script best practices, refer to [AGENTS.md](../AGENTS.md) which defines the coding standards for this repository (strict mode, quoting, error handling, documentation style).
