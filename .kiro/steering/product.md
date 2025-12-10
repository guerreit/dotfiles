# Product Context

## Project Overview

**Dotfiles** is a macOS development environment automation repository that manages personal and work Zsh-based configurations. It streamlines the setup of shell environments, editor configurations, system tweaks, and essential development tools for developers who want a reproducible, consistent development environment across machines.

## Target Users

- **Primary:** Developers working on macOS who frequently set up new machines or maintain multiple workstations
- **Secondary:** Teams that want standardized development environments across members
- **Profile Types:**
  - **Personal Profile:** Individual developers with basic development needs
  - **Work Profile:** Enterprise developers requiring additional tools (AWS, Azure, Terraform, Microsoft suite)

## Core Value Proposition

1. **One-Command Setup:** Single script execution to go from fresh macOS install to fully configured development environment
2. **Profile-Based Configuration:** Tailored tool sets for personal vs work contexts
3. **Safety First:** Automatic backup of existing dotfiles before making changes
4. **Maintenance Simplicity:** Version-controlled configurations that can be easily updated and synchronized
5. **Reproducibility:** Consistent environments across machines and team members

## Key Features

### Environment Setup

- **Shell Configuration:** Oh My Zsh with custom plugins, aliases, functions, and exports
- **Editor Setup:** Vim with vim-plug, Solarized theme, and essential configurations
- **VS Code Extensions:** Automated installation of curated extension set (ESLint, GitLens, Prettier, GitHub Copilot, etc.)
- **Git Configuration:** Profile-aware setup (personal vs work email)

### Package Management

- **Homebrew Packages:** Common CLI tools (git, node, nvm, zoxide, speedtest-cli, yarn, gh)
- **Work-Specific Tools:** AWS CLI, Azure CLI, Terraform (work profile only)
- **GUI Applications:** VS Code (all profiles), plus Postman, Microsoft Edge, Teams, OneNote, Slack (work profile)

### System Optimization

- **macOS Tweaks:** Performance improvements (disabled animations, smooth scrolling, focus rings)
- **Terminal Theme:** Solarized Dark configuration
- **SSH Key Management:** Guided SSH key generation and configuration

### Dotfile Management

- **Comprehensive Coverage:** 15+ dotfiles including `.zshrc`, `.vimrc`, `.gitconfig`, `.aliases`, `.functions`, `.exports`, etc.
- **Safe Syncing:** Backup-first approach prevents accidental data loss
- **Secret Management:** `.secrets` file for sensitive configuration (gitignored)

## User Workflows

### Initial Setup Flow

1. Clone repository
2. Update `.profile` with personal information (Git author name/email)
3. Run `./scripts/setup.sh`
4. Select profile (Personal or Work)
5. Automated installation and configuration
6. Restart terminal to activate new environment

### Maintenance Flow

1. Update configurations in `src/` directory
2. Commit changes to git
3. Run `./scripts/sync.sh` to apply changes
4. Changes synchronized across all machines pulling from repository

### Extension Flow

1. Add new scripts to `scripts/` directory
2. Add new dotfiles to `src/` directory
3. Update `setup.sh` to include new components
4. Document in README.md

## Success Metrics

- **Setup Time:** Complete environment setup in under 15 minutes
- **Reproducibility:** Identical environment across multiple machines
- **Maintenance Effort:** Configuration updates take seconds, not hours
- **Error Recovery:** Safe backups enable quick rollback if issues occur

## Design Philosophy

- **Automation First:** Minimize manual steps, maximize scripted reproducibility
- **Safety:** Always backup before destructive operations
- **Modularity:** Independent scripts for different concerns (brews, casks, sync, etc.)
- **Flexibility:** Profile system supports different use cases without forking
- **Transparency:** Clear logging of all operations for debugging and understanding
- **Convention Over Configuration:** Sensible defaults with escape hatches for customization

## Constraints & Considerations

- **Platform:** macOS-only (relies on Homebrew, macOS-specific tweaks)
- **Shell:** Zsh-focused (macOS default since Catalina)
- **Destructive Operations:** Will overwrite existing dotfiles (mitigated by backups)
- **Network Dependency:** Requires internet for Homebrew and Oh My Zsh installation
- **User Permissions:** May require sudo password for system-level changes

## Future Considerations

- Cross-platform support (Linux, Windows WSL)
- Multiple work profiles (different clients/projects)
- Conditional plugin installation based on detected tools
- Automated testing of configurations
- Integration with cloud-based secret management
- Dry-run mode for previewing changes before applying
