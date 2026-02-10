---
description: Implement features or fix bugs in the dotfiles repository
name: implement
agent: agent
tools:
  - semantic_search
  - grep_search
  - read_file
  - replace_string_in_file
  - multi_replace_string_in_file
  - run_in_terminal
  - file_search
  - list_dir
  - create_file
---

You are implementing a feature or fixing a bug in a **role-aware macOS dotfiles system**. This is a production system used on real machines. Safety, idempotency, and backups are CRITICAL.

## Required Context (Load First)

Before ANY implementation, review these files in ${workspaceFolder}:

1. [.github/copilot-instructions.md](../../copilot-instructions.md) - Architecture, workflows, Git identity system
2. [AGENTS.md](../../AGENTS.md) - Shell scripting standards (strict mode, quoting, error handling)
3. [README.md](../../README.md) - User-facing documentation

## User Request

${input:task:Describe the feature to implement or bug to fix}

## Implementation Process

### 1. Analysis (REQUIRED)

**Understand the request:**

- What layer does it affect? (Source in `src/` | Scripts in `scripts/` | Deployment to `$HOME`)
- Does it impact Git identity management (`.gitconfig.roles`)?
- Does it affect both profiles (personal/work)?
- Which files need modification?

**Search for context:** Use #tool:semantic_search and #tool:grep_search to find related code patterns.

### 2. Implementation Standards

**For shell scripts (`scripts/*.sh`):**

```bash
#!/usr/bin/env zsh
set -euo pipefail  # REQUIRED: Strict mode

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color functions for user feedback
info() { print -P "%F{blue}[INFO]%f $*"; }
success() { print -P "%F{green}[SUCCESS]%f $*"; }
error() { print -P "%F{red}[ERROR]%f $*" >&2; }
warning() { print -P "%F{yellow}[WARNING]%f $*" >&2; }

main() {
    # ALWAYS: Quote variables: "$variable"
    # ALWAYS: Test existence: [[ -f "$file" ]]
    # ALWAYS: Create backups before destructive operations
    # ALWAYS: Make idempotent (safe to run multiple times)
    # ALWAYS: Log actions clearly with color functions
}

main "$@"
```

**Critical rules:**

- Quote ALL variables: `"$variable"` never `$variable`
- Use `[[ ]]` for conditionals, not `[ ]`
- Test file existence before operations: `-f`, `-d`, `-e`, `-x`
- Create timestamped backups: `file.backup.$(date +%Y%m%d_%H%M%S)`
- Check if packages/tools already exist before installing

**For source files (`src/*`):**

- Edit in `src/`, then run `./scripts/sync.sh` to deploy
- NEVER edit deployed files in `$HOME` directly
- Consider impact on both personal and work profiles

**For Git identity features:**

- Source of truth: `src/.gitconfig.roles`
- Update `generate_git_configs()` in `scripts/sync.sh` if needed
- Test with `./scripts/git-config-status.sh` in different directories

### 3. Integration

- **Main setup**: Add to `scripts/setup.sh` if needed during initial install
- **Sync flow**: Update `scripts/sync.sh` if affecting file deployment
- **Dependencies**: Add packages to `scripts/brews.sh` or `scripts/casks.sh` with profile awareness

### 4. Testing & Validation

Before completing:

1. **Syntax**: Run `zsh -n scripts/your-script.sh`
2. **Dry run**: Test with any available dry-run flags
3. **Idempotency**: Run twice, verify no side effects
4. **Both profiles**: Test personal and work if applicable
5. **Error handling**: Test failure scenarios
6. **Backups**: Verify backups are created when expected

For Git identity changes:

```bash
cd ~/Code/personal-project && ./scripts/git-config-status.sh
cd ~/work/project && ./scripts/git-config-status.sh
```

### 5. Output Format

Provide:

1. **Analysis**: What needs to be done and why
2. **Files Modified**: List of changes
3. **Implementation**: The actual code changes
4. **Testing**: How to verify it works
5. **Documentation**: Updates to README or comments if needed

## Common Patterns

**Add new script:**

```bash
touch scripts/new-feature.sh && chmod u+x scripts/new-feature.sh
```

**Add profile-specific package:**

```bash
# In scripts/brews.sh
if [[ "$DOTFILES_PROFILE" == "work" ]]; then
    declare -a PROFILE_BREWS=("docker" "new-tool")
fi
```

**Add Git identity pattern:**

```bash
# In src/.gitconfig.roles
GIT_WORK_PATTERNS=("$HOME/work/**" "$HOME/clients/**" "$HOME/new-pattern/**")
# Then run: ./scripts/sync.sh
```

**Create backup:**

```bash
backup_file() {
    local file="$1"
    [[ -f "$file" ]] && cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
}
```

## Safety Checklist

- [ ] All variables quoted
- [ ] Using `set -euo pipefail`
- [ ] File existence tests before operations
- [ ] Backups created before destructive operations
- [ ] Idempotent (safe to re-run)
- [ ] Clear error messages
- [ ] Works with both profiles (if applicable)
- [ ] Passes `zsh -n` syntax check
- [ ] Tested in clean environment

---

**CRITICAL**: This is production code. Prioritize safety over cleverness. Follow existing patterns. When uncertain, create backups and make changes reversible.
