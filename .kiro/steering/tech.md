# Technical Context

## Technology Stack

### Core Technologies

- **Shell:** Zsh (macOS default since Catalina)
- **Shell Framework:** Oh My Zsh
- **Package Manager:** Homebrew (CLI) + Homebrew Cask (GUI apps)
- **Editor:** Vim with vim-plug plugin manager
- **Version Control:** Git
- **Terminal Theme:** Solarized Dark

### Development Tools (Installed)

- **Node.js Ecosystem:** node, nvm, yarn
- **CLI Tools:** git, zoxide, speedtest-cli, gh (GitHub CLI)
- **Work Profile Tools:** awscli, azure-cli, terraform
- **GUI Applications:** Visual Studio Code, Postman, Microsoft Edge, Teams, OneNote, Slack

### VS Code Extensions (Auto-installed)

- dbaeumer.vscode-eslint
- eamodio.gitlens
- editorconfig.editorconfig
- esbenp.prettier-vscode
- github.copilot
- github.copilot-chat
- redhat.vscode-yaml

## Architecture

### Script Organization

```
dotfiles/
├── scripts/           # Automation scripts
│   ├── setup.sh      # Main orchestrator
│   ├── brews.sh      # Homebrew package installation
│   ├── casks.sh      # GUI application installation
│   ├── osx.sh        # macOS system tweaks
│   ├── plugins.sh    # Oh My Zsh plugin installation
│   ├── sync.sh       # Dotfile synchronization
│   ├── backup.sh     # Backup existing dotfiles
│   ├── ssh-key.sh    # SSH key generation
│   ├── terminal-theme.sh  # Terminal theme application
│   └── vscode-extensions.sh  # VS Code extension management
├── src/              # Source dotfiles
│   ├── .zshrc        # Main Zsh config
│   ├── .vimrc        # Vim config
│   ├── .gitconfig    # Git config
│   ├── .aliases      # Shell aliases
│   ├── .functions    # Shell functions
│   ├── .exports      # Environment variables
│   ├── .path         # PATH modifications
│   ├── .profile      # User-specific settings
│   ├── .secrets      # Sensitive config (gitignored)
│   └── ...
└── README.md         # Documentation
```

### Execution Flow

1. **Entry Point:** `setup.sh`

   - Profile selection prompt
   - Dependency checks
   - Script permission setup
   - Sequential execution of sub-scripts

2. **Installation Sequence:**

   ```
   setup.sh
   ├─> brews.sh (Homebrew packages)
   ├─> casks.sh (GUI applications)
   ├─> plugins.sh (Oh My Zsh setup)
   ├─> vscode-extensions.sh (VS Code extensions)
   ├─> osx.sh (System tweaks)
   ├─> backup.sh (Backup existing files)
   └─> sync.sh (Copy dotfiles to ~/)
   ```

3. **Profile System:**
   - Environment variable: `$DOTFILES_PROFILE` (personal|work)
   - Set at setup.sh prompt, exported for child scripts
   - Scripts read `$DOTFILES_PROFILE` for conditional logic

## Technical Patterns

### Error Handling

```bash
set -euo pipefail  # Exit on error, unset vars, pipe failures
```

- All scripts use strict error handling
- Color-coded logging: info (cyan), success (green), error (red)
- Explicit error messages with context

### Idempotency

- Scripts check for existing installations before attempting install
- Homebrew: `brew list --formula | grep -q "^$pkg$"`
- Oh My Zsh: Check for `$ZSH` directory existence
- VS Code extensions: Check installed extensions before adding

### Modularity

- **Single Responsibility:** Each script handles one concern
- **Independent Execution:** Scripts can run standalone (except setup.sh orchestration)
- **Reusability:** Common functions (info, success, error) defined per script

### Safety Mechanisms

- **Backup First:** `backup.sh` creates timestamped copies before sync
- **Confirmation Prompts:** Profile selection requires explicit user input
- **Dependency Checks:** Verify required commands exist before proceeding
- **Non-Destructive Defaults:** Scripts prefer adding to removing

## Configuration Management

### Dotfile Sources

All dotfiles live in `src/` and are copied to `~/` by `sync.sh`:

- **Shell:** `.zshrc`, `.aliases`, `.functions`, `.exports`, `.path`
- **Git:** `.gitconfig`, `.gitignore`, `.gitattributes`, `.stCommitMsg`
- **Editor:** `.vimrc`, `.editorconfig`
- **Misc:** `.hushlogin`, `.profile`, `.secrets`

### Profile-Aware Configuration

`.gitconfig` uses conditional includes:

```ini
[include]
  path = ~/.gitconfig.personal  # or ~/.gitconfig.work
```

Generated during sync based on `$DOTFILES_PROFILE`

### Secret Management

- `.secrets` file for sensitive environment variables
- Gitignored by default
- Sourced by `.zshrc` if present

## Dependencies

### System Requirements

- macOS (Catalina or later recommended for Zsh default)
- curl (for downloads)
- git (for cloning repository)
- Internet connection (for package downloads)

### External Dependencies

- **Homebrew:** Installed by `brews.sh` if missing
- **Oh My Zsh:** Installed by `plugins.sh`
- **vim-plug:** Auto-installed by `.vimrc` on first Vim launch

### Installation Order Dependencies

1. Homebrew → CLI packages
2. Oh My Zsh → Zsh configuration
3. Dotfiles → Environment activation
4. VS Code → Extension installation

## Performance Considerations

### Optimization Strategies

- **Parallel Package Installation:** Homebrew handles parallelization internally
- **Skip Redundant Operations:** Check before install to avoid unnecessary work
- **Minimal Downloads:** Only install what's needed for selected profile
- **Caching:** Homebrew maintains local cache

### macOS Tweaks

Applied by `osx.sh` for snappier experience:

```bash
# Disable window animations
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Disable smooth scrolling
defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false

# Disable focus ring animations
defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false
```

## Coding Standards

### Shell Script Conventions

- **Shebang:** `#!/usr/bin/env zsh`
- **Error Handling:** `set -euo pipefail`
- **Logging:** Consistent color-coded functions
- **Quotes:** Double-quote all variable expansions
- **Arrays:** Use Zsh array syntax for lists

### File Organization

- **Scripts:** Executable, single-purpose, well-named
- **Dotfiles:** Prefixed with `.`, organized by concern
- **Documentation:** README.md for user-facing, inline comments for maintainers

### Version Control

- **Git Ignore:** `.secrets`, OS-specific files, editor artifacts
- **Commit Messages:** Follow `.stCommitMsg` template
- **Branching:** Not specified (implied single-branch simplicity)

## Testing & Validation

### Current State

- Manual testing on fresh macOS installs
- No automated test suite
- User verification of installed tools and configurations

### Validation Points

- Homebrew packages installed correctly
- Dotfiles copied to home directory
- Zsh sources configuration without errors
- VS Code extensions active
- Git configuration profile-appropriate

## Security Considerations

### SSH Key Management

- `ssh-key.sh` generates new SSH keys
- User prompted for passphrase
- Keys added to ssh-agent
- Public key displayed for copying to services

### Secrets Handling

- `.secrets` file gitignored
- User responsible for manual backup
- Not automatically synchronized to prevent accidental exposure

### Permissions

- Scripts made executable with `chmod u+x`
- No unnecessary sudo usage
- User prompted for password only when required

## Extension Points

### Adding New Packages

1. Add to `COMMON_BREWS` or `PROFILE_BREWS` in `brews.sh`
2. Add to `COMMON_CASKS` or `PROFILE_CASKS` in `casks.sh`

### Adding New Dotfiles

1. Add file to `src/` directory
2. File automatically copied by `sync.sh` (globbing pattern)

### Adding New VS Code Extensions

1. Add extension ID to `EXTENSIONS` array in `vscode-extensions.sh`

### Adding New Profiles

1. Update profile selection in `setup.sh`
2. Add profile-specific logic in relevant scripts
3. Create profile-specific config files (e.g., `.gitconfig.newprofile`)

## Known Limitations

- macOS-only (no Linux/Windows support)
- Single concurrent profile (can't mix personal + work)
- No rollback mechanism beyond manual backup restoration
- Network failures can leave partial installations
- No dry-run mode for previewing changes
