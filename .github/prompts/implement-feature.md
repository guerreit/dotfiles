---
description: Implement features or fix bugs in dotfiles following all architecture patterns and best practices
---

# implement-feature

## Prompt Overview

This prompt helps implement new features or debug existing functionality in the dotfiles repository while following all established conventions, architecture patterns, and best practices.

## Context Loading

Before beginning any implementation, review these critical context files:

1. **Architecture & Conventions**: Read `.github/copilot-instructions.md` to understand:
   - The three-layer architecture (Source/Script/Deployment)
   - Critical workflows (Installation, Sync, Validation)
   - Git identity management system
   - Project-specific conventions

2. **Product Intent**: Review `.github/product.md` to understand:
   - The problem being solved
   - Design philosophy and principles
   - Target users and use cases
   - Key differentiators

3. **Development Standards**: Reference `AGENTS.md` (Shell Script Developer agent) for:
   - Shell scripting best practices (strict mode, quoting, error handling)
   - Security considerations
   - Testing and debugging approaches
   - Code organization patterns

## Implementation Workflow

### Phase 1: Analysis & Planning (REQUIRED)

Before writing any code, complete these steps:

1. **Understand the Request**
   - What feature is being added or what bug is being fixed?
   - Which layer(s) does it affect (Source/Script/Deployment)?
   - Does it impact Git identity management?
   - Does it affect both profiles (personal/work)?

2. **Review Existing Code**
   - Search for related functionality in existing scripts
   - Identify which files need modification
   - Check for similar patterns to follow
   - Look for potential conflicts or dependencies

3. **Plan the Changes**
   - List all files that need to be created or modified
   - Identify potential side effects or breaking changes
   - Determine if backups are needed
   - Plan validation/testing approach

### Phase 2: Implementation (Follow Best Practices)

#### For Shell Scripts (scripts/\*.sh)

Follow ALL guidelines from `AGENTS.md`:

```bash
#!/usr/bin/env zsh
set -euo pipefail

# Constants (paths, defaults)
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color functions (if user-facing)
info() { print -P "%F{blue}[INFO]%f $*"; }
success() { print -P "%F{green}[SUCCESS]%f $*"; }
error() { print -P "%F{red}[ERROR]%f $*" >&2; }
warning() { print -P "%F{yellow}[WARNING]%f $*" >&2; }

# Main function
main() {
    # Always quote variables: "$variable"
    # Use [[ ]] for conditionals
    # Test for existence before operations
    # Log actions clearly
}

main "$@"
```

**Critical Requirements**:

- **Quote all variables**: `"$variable"` never `$variable`
- **Use strict mode**: `set -euo pipefail`
- **Test file existence**: Use `-f`, `-d`, `-e` before operations
- **Create backups**: Before modifying any existing files
- **Make idempotent**: Safe to run multiple times
- **Log clearly**: Use color functions for user feedback
- **Handle errors**: Don't leave system in broken state

#### For Source Files (src/.\*)

- These are templates that get synced to `$HOME`
- Modify in `src/`, then run `./scripts/sync.sh` to deploy
- Never edit deployed files in `$HOME` directly
- Consider both personal and work profiles

#### For Git Identity Features

- **Source of truth**: `src/.gitconfig.roles`
- **Pattern matching**: Add/modify `GIT_WORK_PATTERNS` array
- **Config generation**: Update `generate_git_configs()` in `sync.sh`
- **Validation**: Update `git-config-status.sh` if detection logic changes
- **Test both roles**: Verify personal and work identities work correctly

### Phase 3: Integration

1. **Main Orchestration** (`scripts/setup.sh`)
   - Does this feature need to run during initial setup?
   - Add to appropriate section in orchestration flow
   - Respect the existing order (profile → backup → install → sync → validate)
   - Ensure it works with `$DOTFILES_PROFILE` environment variable

2. **Sync Integration** (`scripts/sync.sh`)
   - Does this affect file deployment?
   - Update rsync exclusions if needed
   - Add to pre-sync validation or post-sync steps
   - Maintain idempotency

3. **Dependencies**
   - Document any new Homebrew packages needed
   - Add to appropriate profile in `brews.sh` or `casks.sh`
   - Check if installed before attempting install

### Phase 4: Testing & Validation

**Before Committing**:

1. **Syntax Check**: Run `zsh -n scripts/your-script.sh`
2. **Shellcheck**: Ensure code passes linting
3. **Dry Run**: Test with dry-run flags if available
4. **Profile Testing**: Test both personal and work profiles if applicable
5. **Backup Verification**: Confirm backups are created when expected
6. **Error Handling**: Test failure scenarios
7. **Idempotency**: Run script twice, verify no side effects

**For Git Identity Changes**:

```bash
# Test in different directories
cd ~/Code/personal-project
./scripts/git-config-status.sh

cd ~/work/company-project
./scripts/git-config-status.sh

# Verify correct identity is detected
git config user.name
git config user.email
```

### Phase 5: Documentation

Update relevant documentation:

1. **README.md**: If adding user-facing features or new scripts
2. **Code Comments**: Explain "why" not "what"
3. **Function Headers**: Document args, return values, side effects
4. **Copilot Instructions**: Update if changing architecture or conventions

## Common Implementation Patterns

### Adding a New Script

```bash
# 1. Create script in scripts/ directory
touch scripts/new-feature.sh
chmod u+x scripts/new-feature.sh

# 2. Use template from AGENTS.md
# 3. Add to setup.sh orchestration if needed
# 4. Document in README.md
```

### Adding Profile-Specific Package

```bash
# In scripts/brews.sh or scripts/casks.sh
if [[ "$DOTFILES_PROFILE" == "work" ]]; then
    declare -a PROFILE_BREWS=(
        "docker"
        "kubernetes-cli"
        "new-work-tool"  # Add here
    )
fi

# Check before installing
for pkg in "${PROFILE_BREWS[@]}"; do
    if ! brew list --formula | grep -q "^${pkg}$"; then
        info "Installing ${pkg}..."
        brew install "$pkg"
    fi
done
```

### Adding Git Identity Pattern

```bash
# In src/.gitconfig.roles
# Add work directory patterns
GIT_WORK_PATTERNS=(
    "$HOME/work/**"
    "$HOME/clients/**"
    "$HOME/new-work-location/**"  # Add new pattern
)

# Run sync to regenerate configs
./scripts/sync.sh
```

### Creating Backup Before Changes

```bash
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        success "Backed up: $file → $backup"
    fi
}

# Use before modifying
backup_file "$HOME/.zshrc"
# Now safe to modify
```

## Debugging Existing Features

### Systematic Debugging Approach

1. **Identify the Issue**
   - What's the expected behavior?
   - What's the actual behavior?
   - When did it start happening?
   - Which component is affected?

2. **Gather Context**
   - Read relevant scripts completely
   - Check related configuration files
   - Review recent changes (git log)
   - Look for error messages or logs

3. **Isolate the Problem**
   - Run scripts with `set -x` for debug output: `zsh -x script.sh`
   - Test individual functions in isolation
   - Check intermediate state (files created, variables set)
   - Verify assumptions (file paths, permissions, environment vars)

4. **Fix and Verify**
   - Apply minimal fix that addresses root cause
   - Test fix in clean environment if possible
   - Verify no new side effects introduced
   - Update validation/tests to catch regression

### Common Issues & Solutions

**Issue**: Script fails with "command not found"

- **Check**: Is the command in PATH? Use `which command` or `command -v command`
- **Fix**: Install missing dependency or add path to PATH

**Issue**: Variable expansion not working

- **Check**: Are variables quoted? Using correct syntax?
- **Fix**: Always use `"$variable"` or `"${variable}"`

**Issue**: File not found errors

- **Check**: Using absolute or relative paths? Does file exist?
- **Fix**: Use absolute paths or check existence with `[[ -f "$file" ]]`

**Issue**: Git identity not switching

- **Check**: Run `./scripts/git-config-status.sh` to see active identity
- **Fix**: Verify patterns in `src/.gitconfig.roles`, run `sync.sh`

**Issue**: Script not idempotent (fails on second run)

- **Check**: Does it test for existing state before acting?
- **Fix**: Add checks like "if not installed, then install"

**Issue**: Backup not created

- **Check**: Is backup function being called? Correct file path?
- **Fix**: Ensure backup happens BEFORE modification

## Safety Checklist

Before finalizing any implementation:

- [ ] All variables are quoted
- [ ] Using `set -euo pipefail` (strict mode)
- [ ] Files tested for existence before operations
- [ ] Backups created before destructive operations
- [ ] Changes are idempotent (safe to re-run)
- [ ] Error messages are clear and actionable
- [ ] Success/progress messages inform user
- [ ] Works with both personal and work profiles (if applicable)
- [ ] Doesn't break existing functionality
- [ ] Code passes `zsh -n` syntax check
- [ ] Code follows patterns in `AGENTS.md`
- [ ] Documentation is updated
- [ ] Tested in clean environment

## Example Usage

**Adding a new feature**:

```
I want to add a script that installs Python packages from a requirements.txt file.
It should support both global and virtual environment installation.

Context needed:
- Review package management patterns in brews.sh
- Follow shell scripting guidelines in AGENTS.md
- Make it profile-aware (different packages for personal/work)
- Integrate with setup.sh orchestration
```

**Debugging an issue**:

```
The Git identity is not switching correctly in subdirectories.
Expected: Work identity in ~/work/project/subdir
Actual: Personal identity being used

Debug steps:
- Check pattern matching in git-config-status.sh
- Verify GIT_WORK_PATTERNS in .gitconfig.roles
- Test glob pattern matching with different paths
- Verify conditional includes in generated .gitconfig
```

## Output Format

When implementing features, structure your response:

1. **Analysis Summary**: Brief explanation of what needs to be done
2. **Files to Modify**: List of all files that will be changed/created
3. **Implementation**: Show the actual code changes
4. **Testing Steps**: How to verify the changes work
5. **Integration Notes**: Any updates needed to other scripts or docs

Keep changes focused, minimal, and aligned with existing patterns.

---

**Remember**: This is a production dotfiles system used on real machines. Safety, idempotency, and backups are not optional. When in doubt, follow the patterns that already exist in the codebase.
