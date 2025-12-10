# Research & Design Decisions

---

## **Purpose**: Capture discovery findings, architectural investigations, and rationale that inform the technical design.

## Summary

- **Feature**: `git-config-role`
- **Discovery Scope**: Extension
- **Key Findings**:
  - Git's `includeIf` directive supports conditional configuration based on directory paths (`gitdir:`) and other conditions
  - Current implementation uses manual profile selection during setup and basic environment detection in `.profile`
  - Existing structure already supports profile-based configuration through `$DOTFILES_PROFILE` environment variable

## Research Log

### Git Conditional Includes Feature

- **Context**: Need to understand Git's native support for role-based configuration
- **Sources Consulted**: Git documentation (git-config man page), Git 2.13+ release notes
- **Findings**:
  - `includeIf "gitdir:path"` directive available since Git 2.13 (2017)
  - Supports glob patterns and `**` for recursive directory matching
  - Path matching is case-sensitive on Unix systems
  - Multiple `includeIf` sections can coexist, last match wins
  - Conditions evaluated when Git runs in a repository context
- **Implications**: Can use native Git features without external tooling; requires Git 2.13+ (satisfied on modern macOS)

### Current Implementation Analysis

- **Context**: Understanding existing profile system to ensure backward compatibility
- **Sources Consulted**: `scripts/setup.sh`, `src/.profile`, `src/.gitconfig`, `scripts/sync.sh`
- **Findings**:
  - `setup.sh` prompts user for profile selection (personal/work) and exports `$DOTFILES_PROFILE`
  - `.profile` contains basic role detection logic checking `$DOTFILES_PROFILE`, `$WORK_PROFILE`, hostname, and `$PWD`
  - `.profile` sets global Git config using `git config --global user.name` and `user.email`
  - Current `.gitconfig` does NOT use conditional includes yet (mentioned in steering but not implemented)
  - `sync.sh` copies dotfiles from `src/` to `~/` with backup
- **Implications**: Need to migrate from global config approach to conditional includes; `.profile` logic can be basis for new config file

### Configuration File Format Options

- **Context**: Deciding on format for role configuration storage
- **Sources Consulted**: Project steering documents, existing dotfiles patterns
- **Findings**:
  - Project uses shell scripts extensively (`.zshrc`, `.profile`, `.aliases`)
  - JSON/YAML would require additional parsing tools
  - Shell-sourceable format aligns with existing patterns
  - `.profile` already demonstrates this pattern
- **Implications**: Use shell-sourceable `.gitconfig.roles` file for configuration storage

### Directory Pattern Detection Strategy

- **Context**: How to automatically detect work vs personal context
- **Sources Consulted**: Current `.profile` implementation, common development directory patterns
- **Findings**:
  - Developers commonly organize by top-level directories (`~/work/`, `~/personal/`, `~/clients/`)
  - Hostname-based detection less reliable (machines used for both contexts)
  - Path-based detection most reliable and explicit
  - Environment variables useful for override scenarios
- **Implications**: Prioritize directory-based detection with environment variable fallback

## Architecture Pattern Evaluation

| Option                     | Description                                           | Strengths                               | Risks / Limitations                                      | Notes                                             |
| -------------------------- | ----------------------------------------------------- | --------------------------------------- | -------------------------------------------------------- | ------------------------------------------------- |
| Global Git Config Override | Continue using `git config --global` at shell startup | Simple, no changes needed               | Not per-repository, race conditions with parallel shells | Current approach, not suitable for mixed contexts |
| Git Conditional Includes   | Use `includeIf` in main `.gitconfig`                  | Native Git support, per-repo, automatic | Requires Git 2.13+, path configuration needed            | Recommended - aligns with Git best practices      |
| Git Hooks                  | Use `post-checkout` hooks to set local config         | Flexible, can handle complex logic      | Must install in every repo, maintenance overhead         | Overly complex for this use case                  |
| Wrapper Script             | Wrap `git` command with detection logic               | Full control, custom logic              | Breaks IDE integrations, performance overhead            | Not recommended                                   |

## Design Decisions

### Decision: Use Git Conditional Includes as Primary Mechanism

- **Context**: Need automatic, per-repository role detection that doesn't require manual intervention
- **Alternatives Considered**:
  1. Global config override at shell startup - not per-repo aware
  2. Git hooks - too complex, per-repo installation burden
  3. Wrapper script - breaks tooling integration
- **Selected Approach**: Leverage Git's native `includeIf` directive in `.gitconfig` with directory patterns
- **Rationale**: Native Git feature, zero runtime overhead, works with all Git tools (CLI, IDEs, GUI clients), explicitly configured and predictable
- **Trade-offs**: Requires upfront directory pattern configuration, less "magic" than heuristic detection
- **Follow-up**: Provide clear documentation and helper script for users to configure their directory patterns

### Decision: Configuration File Structure

- **Context**: Need human-editable format for storing role-specific Git identities and directory patterns
- **Alternatives Considered**:
  1. JSON/YAML - requires parsing tools, less aligned with shell ecosystem
  2. INI-style (Git config format) - readable but requires `git config` commands to edit
  3. Shell-sourceable file - aligns with existing dotfiles patterns
- **Selected Approach**: Create `.gitconfig.roles` as shell-sourceable configuration file, plus separate `.gitconfig.personal` and `.gitconfig.work` files for Git includes
- **Rationale**: Aligns with existing dotfiles patterns (`.profile`, `.aliases`, `.exports`), easy to edit manually, can be sourced by scripts
- **Trade-offs**: Not a standard format, requires documentation
- **Follow-up**: Provide template with clear comments and examples

### Decision: Backward Compatibility Strategy

- **Context**: Existing users have `.profile` with Git configuration logic
- **Alternatives Considered**:
  1. Breaking change - require migration
  2. Dual mode - support both old and new
  3. Automatic migration - detect and convert
- **Selected Approach**: Automatic migration during sync - detect old pattern, create new config files, preserve old `.profile` with deprecation notice
- **Rationale**: Smooth upgrade path, no user action required, preserves customizations
- **Trade-offs**: Added complexity in `sync.sh`, temporary dual code paths
- **Follow-up**: Add migration detection and conversion logic to `sync.sh`

### Decision: Default Directory Patterns

- **Context**: Need sensible defaults for work directory detection
- **Alternatives Considered**:
  1. No defaults - require explicit configuration
  2. Common patterns - provide typical work directory patterns
  3. Interactive setup - ask user during installation
- **Selected Approach**: Provide common pattern defaults in template (e.g., `~/work/**`, `~/clients/**`, `~/code/work/**`) with clear documentation on customization
- **Rationale**: Reduces setup friction, covers common cases, still allows customization
- **Trade-offs**: Defaults may not match all workflows
- **Follow-up**: Document customization process clearly in README

### Decision: Validation and Status Command

- **Context**: Users need to verify which configuration is active
- **Alternatives Considered**:
  1. No tooling - rely on `git config --get`
  2. Simple script - display current config
  3. Comprehensive tool - show detection logic, patterns, overrides
- **Selected Approach**: Create `scripts/git-config-status.sh` that shows detected role, active config, matching patterns, and suggests fixes for issues
- **Rationale**: Improves debuggability, builds user confidence, reduces support burden
- **Trade-offs**: Additional maintenance surface
- **Follow-up**: Include in setup script execution and document in README

## Risks & Mitigations

- **Risk**: Git version < 2.13 doesn't support `includeIf` - **Mitigation**: Check Git version in setup script, fall back to global config with warning
- **Risk**: Directory patterns don't match user's organization - **Mitigation**: Provide clear examples and validation script, log detected configuration
- **Risk**: Conditional includes not evaluated in bare repositories - **Mitigation**: Document limitation, rare edge case for dotfiles use case
- **Risk**: Users manually edit `.gitconfig` and break includes - **Mitigation**: Add comments in `.gitconfig` warning about structure, provide repair script
- **Risk**: Migration from old approach loses customizations - **Mitigation**: Preserve original `.profile`, create `.profile.backup`, log migration actions

## References

- [Git Conditional Includes Documentation](https://git-scm.com/docs/git-config#_conditional_includes) - Official Git documentation
- [Git 2.13 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.13.0.txt) - Introduction of `includeIf` feature
- Existing implementation: `src/.profile`, `scripts/setup.sh`, `scripts/sync.sh`
