# Research & Design Decisions

## Summary

- **Feature**: `profile-config-management`
- **Discovery Scope**: Extension
- **Key Findings**:
  - 86% of functionality already implemented with established patterns
  - Primary gap is direct `git config --global` execution during setup/sync
  - All Zsh scripting patterns are well-established in existing codebase
  - No external dependencies or unfamiliar technologies required

## Research Log

### Existing Function Patterns

- **Context**: Analyzed all script files to understand established patterns for function definition and usage
- **Sources Consulted**: grep_search across scripts/ directory
- **Findings**:
  - All scripts use consistent logging pattern: `info()`, `success()`, `error()`, `warning()` functions
  - Scripts use Zsh's `print -P` with ANSI color codes for output
  - Error handling follows `set -euo pipefail` standard across all scripts
  - Functions defined inline at top of each script (no shared function library)
- **Implications**: New functions should follow same inline definition pattern with consistent logging

### Git Configuration Architecture

- **Context**: Understanding current Git config generation and conditional include system
- **Sources Consulted**: sync.sh lines 113-235, .gitconfig.roles, gap-analysis.md
- **Findings**:
  - `generate_git_configs()` function sources `.gitconfig.roles` and generates `.gitconfig.personal/.work` files
  - Conditional includes use `includeIf "gitdir:..."` for directory-based identity switching
  - Git version check (`check_git_version()`) validates 2.13+ for conditional include support
  - No current execution of `git config --global` commands
- **Implications**: New function `set_git_global_config()` should be added after `generate_git_configs()` to set global fallback identity

### Profile Persistence Flow

- **Context**: How profile selection propagates through the system
- **Sources Consulted**: setup.sh lines 15-35, sync.sh line 126
- **Findings**:
  - setup.sh prompts for profile and exports `DOTFILES_PROFILE` environment variable
  - sync.sh accepts profile as argument `$1` and updates `GIT_DEFAULT_ROLE` in `.gitconfig.roles`
  - Profile persistence happens in sync.sh, not immediately after selection in setup.sh
- **Implications**: Add early persistence in setup.sh before calling child scripts to ensure `.gitconfig.roles` is updated first

### SSH Key Integration

- **Context**: Understanding ssh-key.sh's current implementation and integration points
- **Sources Consulted**: ssh-key.sh entire file, setup.sh execution flow
- **Findings**:
  - ssh-key.sh currently accepts email arguments with hardcoded defaults
  - Script not called by setup.sh - manual execution required
  - Script already handles key existence checks, ssh-agent, and config updates
  - No dynamic sourcing of `.gitconfig.roles` for email values
- **Implications**: Modify ssh-key.sh to source `.gitconfig.roles` for emails, add optional prompt in setup.sh

## Architecture Pattern Evaluation

| Option                         | Description                                       | Strengths                            | Risks / Limitations                        | Notes                                   |
| ------------------------------ | ------------------------------------------------- | ------------------------------------ | ------------------------------------------ | --------------------------------------- |
| **Extend Existing (Selected)** | Add functions to sync.sh, setup.sh, ssh-key.sh    | Minimal code, follows patterns, fast | Slightly increases file complexity         | Gap analysis shows 90% complete         |
| Create Profile Manager         | New scripts/profile-manager.sh centralizing logic | Clean separation                     | Overkill for 2-profile system, indirection | Future consideration if profiles expand |
| Minimal + Documentation        | Only add git config execution, document SSH       | Fastest implementation               | Incomplete automation, manual steps remain | Doesn't meet requirements fully         |

## Design Decisions

### Decision: Add Git Global Config Function to sync.sh

- **Context**: Requirements 2.1-2.5 mandate direct `git config --global` execution based on profile
- **Alternatives Considered**:
  1. Execute in setup.sh only - Simple but doesn't update on sync
  2. Execute in sync.sh always - Ensures consistency on any sync operation
  3. Create separate profile-manager.sh - Clean but adds complexity
- **Selected Approach**: Add `set_git_global_config()` function to sync.sh
- **Rationale**: sync.sh already handles all Git configuration logic, consistent with existing architecture
- **Trade-offs**:
  - ✅ Centralizes Git config in one place
  - ✅ Works for both setup and manual sync operations
  - ❌ Overwrites manual user changes to global config (acceptable per requirements)
- **Follow-up**: Ensure function respects `PROFILE_CHOICE` argument or falls back to `GIT_DEFAULT_ROLE`

### Decision: Profile Persistence Before Child Script Execution

- **Context**: Requirement 1.3 requires persisting profile choice in `.gitconfig.roles`
- **Alternatives Considered**:
  1. Keep current behavior (sync.sh updates) - Works but has timing gap
  2. Add early update in setup.sh - Ensures immediate persistence
- **Selected Approach**: Add function in setup.sh to update `.gitconfig.roles` immediately after profile selection
- **Rationale**: Ensures single source of truth is updated before any scripts read it
- **Trade-offs**:
  - ✅ Eliminates timing window between selection and persistence
  - ✅ All child scripts see consistent profile value
  - ❌ Adds ~15 lines to setup.sh
- **Follow-up**: Use sed to update `GIT_DEFAULT_ROLE` line in place

### Decision: Optional SSH Key Generation with Profile Integration

- **Context**: Requirements 3.x and 4.1 require profile-aware SSH key generation
- **Alternatives Considered**:
  1. Mandatory SSH generation - Forces users, too aggressive
  2. Optional prompt with profile emails - User choice, automatic email usage
  3. Keep manual only - Doesn't meet automation requirements
- **Selected Approach**: Optional prompt in setup.sh with dynamic email sourcing in ssh-key.sh
- **Rationale**: Balances automation with user choice, respects existing ssh-key.sh design
- **Trade-offs**:
  - ✅ Users can skip if keys already exist
  - ✅ Automatic email consistency when generated
  - ❌ Optional means some users may skip
- **Follow-up**: ssh-key.sh should source `.gitconfig.roles` and use `GIT_PERSONAL_EMAIL`/`GIT_WORK_EMAIL`

### Decision: Email Source of Truth

- **Context**: Requirement 4.x requires email consistency across Git and SSH
- **Alternatives Considered**:
  1. Multiple sources (.profile, hardcoded, .gitconfig.roles) - Current fragmented state
  2. Single source with fallbacks - `.gitconfig.roles` as canonical source
- **Selected Approach**: `.gitconfig.roles` as single source of truth with backward-compatible fallbacks
- **Rationale**: Aligns with existing role-based system, simplifies mental model
- **Trade-offs**:
  - ✅ Single file to maintain
  - ✅ Consistent across all tools
  - ❌ Requires `.gitconfig.roles` to be properly configured
- **Follow-up**: Maintain hardcoded fallbacks in ssh-key.sh for standalone execution

## Risks & Mitigations

- **Risk**: Git config --global overwrites manual user changes

  - **Mitigation**: Document behavior clearly, users can edit `.gitconfig.roles` and re-run sync

- **Risk**: Users skip SSH key generation and maintain inconsistent emails

  - **Mitigation**: Clear prompts explaining purpose, display resulting emails for verification

- **Risk**: sed update of .gitconfig.roles could fail with unexpected file format

  - **Mitigation**: Validate file exists and contains expected `GIT_DEFAULT_ROLE=` line before update

- **Risk**: Sourcing .gitconfig.roles in ssh-key.sh could fail if file malformed
  - **Mitigation**: Use fallback to hardcoded defaults if sourcing fails, log warning

## References

- [Git Conditional Includes Documentation](https://git-scm.com/docs/git-config#_conditional_includes) - Git 2.13+ feature for directory-based config
- [Zsh print Command](https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html#index-print) - ANSI color code formatting
- [SSH Key Best Practices](https://www.ssh.com/academy/ssh/keygen) - ED25519 key generation and management
