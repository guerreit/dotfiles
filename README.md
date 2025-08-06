# Dotfiles (ZSH)

This repository manages your personal and work Zsh-based development environment on macOS. It automates the setup of your shell, editor, system tweaks, and essential tools, inspired by [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles/) and [paulirish/dotfiles](https://github.com/paulirish/dotfiles).

## Features
- **Profile-based setup:** Choose between Personal and Work profiles for tailored tools and apps.
- **Automated Homebrew & Cask installs:** Installs CLI tools (git, node, yarn, etc.) and apps (VS Code, Slack, etc. for work).
- **Zsh & Vim configuration:** Sets up Oh My Zsh, plugins, aliases, and Vim with Solarized theme and vim-plug.
- **VS Code extensions:** Installs and manages a curated set of essential extensions.
- **macOS tweaks:** Applies UI and performance improvements for a snappier experience.
- **Safe dotfile syncing:** Backs up your existing dotfiles before replacing them.
- **SSH key management:** Includes script for SSH key generation and configuration.
- **Terminal theme:** Includes Solarized Dark terminal theme configuration.

## Installation

**Warning:** This will overwrite your existing dotfiles. Back up anything important first!

1. Clone this repo:
   ```sh
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles
   ```
2. Update properties in `src/.profile` as needed (Git author name/email).
3. Run the setup script:
   ```sh
   ./scripts/setup.sh
   ```
   - You will be prompted to select a profile (Personal or Work).

## What gets installed/configured?

### Homebrew Packages
- **Common:** git, node, nvm, zoxide, speedtest-cli, yarn, gh
- **Work profile only:** awscli, azure-cli, terraform

### Cask Applications
- **Common:** Visual Studio Code
- **Work profile only:** Postman, Microsoft Edge, Microsoft Teams, Microsoft OneNote, Slack

### Zsh Configuration
- Oh My Zsh installation and configuration
- Custom plugins, aliases, exports, and functions
- Profile-based Git configuration (personal vs work email)

### Vim Configuration
- vim-plug plugin manager
- Solarized Dark theme
- Custom vimrc with essential settings

### VS Code Extensions
Essential extensions automatically installed:
- ESLint
- GitLens
- EditorConfig
- Prettier
- GitHub Copilot
- GitHub Copilot Chat
- YAML support

### macOS System Tweaks
- Disables window animations for snappier performance
- Disables smooth scrolling
- Disables focus ring animations

### Dotfile Sync
All files in `src/` are copied to your home directory, including:
- `.zshrc` - Main Zsh configuration
- `.vimrc` - Vim configuration
- `.gitconfig` - Git configuration
- `.aliases` - Custom shell aliases
- `.exports` - Environment variables
- `.functions` - Custom shell functions
- `.editorconfig` - Editor configuration
- `.gitignore` - Global Git ignore rules
- `.gitattributes` - Git attributes
- `.hushlogin` - Suppress login banner
- `.path` - PATH modifications
- `.stCommitMsg` - Git commit message template
- `.secrets` - For sensitive configuration (not tracked)

## Additional Scripts

- `scripts/backup.sh` - Creates backups of existing dotfiles
- `scripts/ssh-key.sh` - Generates and configures SSH keys
- `scripts/terminal-theme.sh` - Applies Solarized Dark terminal theme
- `scripts/plugins.sh` - Installs Oh My Zsh plugins

## Profile System

The setup uses a profile system to configure different environments:

- **Personal Profile:** Basic development tools with personal Git configuration
- **Work Profile:** Additional work-specific tools (AWS CLI, Azure CLI, Terraform, Microsoft apps) with work Git configuration

## Credits
- Inspired by [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles/) and [paulirish/dotfiles](https://github.com/paulirish/dotfiles/)

---
Feel free to fork and adapt for your own workflow!
