# Product Intent

## Overview

This dotfiles repository provides a **reproducible macOS development environment** that can be deployed with a single command. It's designed to eliminate the tedious, error-prone process of manually configuring a new machine or maintaining consistency across multiple development setups.

## Problem Statement

Developers face several recurring challenges when setting up new machines or maintaining multiple environments:

1. **Manual Configuration is Time-Consuming**: Installing packages, configuring shell environments, setting up Git identities, and applying system preferences can take hours or even days.

2. **Inconsistency Across Machines**: Without automation, personal and work machines drift apart in configuration, leading to "works on my machine" problems.

3. **Risk of Data Loss**: Manually copying configuration files can accidentally overwrite important settings without backups.

4. **Git Identity Confusion**: Using the wrong Git identity (personal email in work repos, or vice versa) creates professional embarrassment and compliance issues.

5. **Profile Fragmentation**: Personal and work environments need different tools, but managing separate dotfile repositories is cumbersome.

## Solution

This repository solves these problems through:

### 1. **One-Command Setup**

A single `./scripts/setup.sh` command orchestrates the entire environment configuration:

- Homebrew package installation (CLI tools and GUI apps)
- Shell environment (Oh My Zsh, plugins, themes)
- Editor configuration (Vim, VS Code extensions)
- System preferences (macOS UI tweaks)
- SSH key generation and configuration
- Dotfile synchronization with automatic backups

### 2. **Profile-Aware Installation**

Choose "Personal" or "Work" during setup to:

- Install different sets of CLI tools and GUI applications
- Configure appropriate default Git identities
- Maintain role separation while using a single repository

### 3. **Automatic Git Identity Management**

A sophisticated role-based system ensures you always commit with the correct identity:

- Define personal and work Git identities in a single source file (`src/.gitconfig.roles`)
- Configure directory patterns (e.g., `~/work/**` uses work identity)
- Automatically apply the correct identity based on where you're working
- Validate configuration with `git-config-status.sh`

### 4. **Safety-First Philosophy**

Multiple layers of protection prevent data loss:

- Automatic timestamped backups before any file is overwritten
- Idempotent scripts that can be safely re-run
- Validation steps before applying changes
- Clear logging of all actions taken

### 5. **Developer Experience Focus**

Designed for real-world usage patterns:

- Optional SSH key generation for personal/work separation
- Terminal theme integration (Solarized)
- Editor plugins and extensions pre-configured
- Shell aliases and functions ready to use
- macOS system optimizations for productivity

## Target Users

This solution is ideal for:

- **macOS developers** who regularly set up new machines or maintain multiple environments
- **Consultants and contractors** who need to separate personal and client work
- **DevOps engineers** who value infrastructure-as-code principles for their local environment
- **Teams** who want standardized development environments across members
- **Anyone** who's experienced the pain of manual machine setup

## Key Differentiators

1. **Role-Based Git Identity**: Unlike most dotfile repos, this provides sophisticated, pattern-based Git identity switching that actually works reliably.

2. **Profile System**: Single repository serves both personal and work needs without maintaining separate forks or branches.

3. **Comprehensive Backup Strategy**: Multiple backup mechanisms ensure you never lose configuration.

4. **SSH Key Management**: Optional but integrated SSH setup with separate personal/work keys, proper permissions, and keychain integration.

5. **Production-Ready**: Not just configuration files—includes installation, backup, validation, and status reporting scripts.

## Design Philosophy

This codebase follows several core principles:

- **Idempotency**: All scripts can be safely re-run without side effects
- **Transparency**: Clear logging shows exactly what's happening
- **Modularity**: Each script handles one concern (backup, sync, packages, etc.)
- **Safety**: Multiple backup strategies and validation steps
- **Portability**: Follows shell scripting best practices (see `AGENTS.md`)
- **Maintainability**: Well-documented, clear code structure

## Success Metrics

This solution is successful when it:

1. Reduces new machine setup time from hours/days to minutes
2. Eliminates Git identity mistakes across personal/work repositories
3. Provides confidence to update configurations without fear of data loss
4. Maintains consistency across multiple development machines
5. Enables quick experimentation and rollback of configuration changes

## Future Considerations

Potential enhancements include:

- Linux support (currently macOS-focused)
- Additional profile types (freelance, open-source, etc.)
- Cloud-based backup integration
- Configuration validation and testing framework
- Dotfile versioning and rollback capabilities
- Template customization system for teams

## Getting Started

New users should:

1. Review the [README.md](../README.md) for prerequisites and installation steps
2. Customize `src/.gitconfig.roles` with their identities and directory patterns
3. Run `./scripts/setup.sh` and select their profile
4. Verify Git configuration with `./scripts/git-config-status.sh`

For developers contributing to this repository, see [AGENTS.md](../AGENTS.md) for shell scripting guidelines and best practices.
