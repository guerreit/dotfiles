# Dotfiles (ZSH)

This repository manages your personal and work Zsh-based development environment on macOS. It automates the setup of your shell, editor, system tweaks, and essential tools, inspired by [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles/) and [paulirish/dotfiles](https://github.com/paulirish/dotfiles).

## Features
- **Profile-based setup:** Choose between Personal and Work profiles for tailored tools and apps.
- **Automated Homebrew & Cask installs:** Installs CLI tools (git, node, yarn, etc.) and apps (VS Code, Slack, etc. for work).
- **Zsh & Vim configuration:** Sets up Oh My Zsh, plugins, aliases, and Vim with Solarized theme and vim-plug.
- **VS Code extensions:** Installs and manages a curated set of extensions.
- **macOS tweaks:** Applies UI and performance improvements.
- **Safe dotfile syncing:** Backs up your existing dotfiles before replacing them.

## Installation

**Warning:** This will overwrite your existing dotfiles. Back up anything important first!

1. Clone this repo:
   ```sh
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles
   ```
2. Update properties in `src/.profile` as needed.
3. Run the setup script:
   ```sh
   ./scripts/setup.sh
   ```
   - You will be prompted to select a profile (Personal or Work).

## What gets installed/configured?
- **Homebrew packages:** git, node, nvm, zoxide, speedtest-cli, yarn, gh, and (for work) awscli, azure-cli, terraform
- **Cask apps:** Visual Studio Code, and (for work) Postman, Microsoft Edge, Teams, OneNote, Slack
- **Zsh:** Oh My Zsh, custom plugins, aliases, exports, and functions
- **Vim:** vim-plug, Solarized theme
- **VS Code extensions:** ESLint, GitLens, EditorConfig, Prettier, Copilot, YAML, and more
- **macOS tweaks:** Disables window/smooth scrolling/focus ring animations for a snappier experience
- **Dotfile sync:** All files in `src/` are copied to your home directory, with backups of any existing files

## Credits
- Inspired by [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles/) and [paulirish/dotfiles](https://github.com/paulirish/dotfiles/)

---
Feel free to fork and adapt for your own workflow!
