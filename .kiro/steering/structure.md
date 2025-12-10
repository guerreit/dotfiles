# Project Structure

## Directory Layout

```
dotfiles/
├── .kiro/                      # AI development lifecycle configuration
│   └── steering/               # Project-wide AI guidance
│       ├── product.md         # Product context and vision
│       ├── tech.md            # Technical architecture and standards
│       └── structure.md       # This file - project organization
├── scripts/                    # Automation scripts
│   ├── setup.sh               # Main orchestrator - entry point
│   ├── brews.sh               # Homebrew package installation
│   ├── casks.sh               # GUI application installation (Homebrew Cask)
│   ├── osx.sh                 # macOS system preference tweaks
│   ├── plugins.sh             # Oh My Zsh installation and plugin setup
│   ├── sync.sh                # Dotfile synchronization to home directory
│   ├── backup.sh              # Backup existing dotfiles before overwriting
│   ├── ssh-key.sh             # SSH key generation and configuration
│   ├── terminal-theme.sh      # Terminal theme application (Solarized Dark)
│   └── vscode-extensions.sh   # VS Code extension installation
├── src/                        # Source dotfiles (copied to ~/ by sync.sh)
│   ├── .zshrc                 # Main Zsh configuration
│   ├── .vimrc                 # Vim configuration
│   ├── .gitconfig             # Git configuration
│   ├── .aliases               # Custom shell aliases
│   ├── .functions             # Custom shell functions
│   ├── .exports               # Environment variable exports
│   ├── .path                  # PATH modifications
│   ├── .profile               # User-specific settings (name, email)
│   ├── .secrets               # Sensitive configuration (gitignored)
│   ├── .editorconfig          # Editor configuration for consistency
│   ├── .gitignore             # Global Git ignore patterns
│   ├── .gitattributes         # Git attributes (line endings, etc.)
│   ├── .hushlogin             # Suppress login banner
│   └── .stCommitMsg           # Git commit message template
├── AGENTS.md                   # AI agent development guidelines
├── LICENSE.txt                 # License information
├── README.md                   # User-facing documentation
└── Solarized Dark.terminal     # Terminal theme configuration file
```

## Component Relationships

### Script Dependencies

```
User runs: ./scripts/setup.sh
           │
           ├─> Profile Selection (personal|work)
           │   └─> Exports $DOTFILES_PROFILE
           │
           ├─> chmod (make scripts executable)
           │
           ├─> scripts/brews.sh
           │   ├─> brew install (common packages)
           │   └─> brew install (profile-specific packages)
           │
           ├─> scripts/casks.sh
           │   ├─> brew install --cask (common apps)
           │   └─> brew install --cask (profile-specific apps)
           │
           ├─> scripts/plugins.sh
           │   ├─> Install Oh My Zsh
           │   └─> Install Zsh plugins
           │
           ├─> scripts/vscode-extensions.sh
           │   └─> code --install-extension (for each extension)
           │
           ├─> scripts/osx.sh
           │   └─> defaults write (macOS preferences)
           │
           ├─> scripts/backup.sh
           │   └─> cp existing dotfiles → ~/dotfiles-backup-TIMESTAMP/
           │
           └─> scripts/sync.sh
               └─> cp src/.* → ~/
```

### Dotfile Loading Order

```
Zsh Shell Startup:
1. /etc/zshenv
2. ~/.zshenv (not used in this repo)
3. /etc/zprofile
4. ~/.zprofile (not used in this repo)
5. /etc/zshrc
6. ~/.zshrc (main config)
   ├─> sources ~/.path
   ├─> sources ~/.exports
   ├─> sources ~/.aliases
   ├─> sources ~/.functions
   └─> sources ~/.secrets (if exists)
```

### Configuration Flow

```
src/.profile (user edits)
     │
     ↓
setup.sh (reads profile choice)
     │
     ↓
sync.sh (generates profile-specific configs)
     │
     ├─> ~/.gitconfig (includes ~/.gitconfig.personal or ~/.gitconfig.work)
     └─> All src/.* files → ~/
```

## File Naming Conventions

### Scripts

- **Pattern:** `<action>.sh` (verb-based naming)
- **Location:** `scripts/` directory
- **Permissions:** Executable (`chmod u+x`)
- **Shebang:** `#!/usr/bin/env zsh`

### Dotfiles

- **Pattern:** `.<name>` (hidden files with leading dot)
- **Location:** `src/` directory (source) → `~/` (deployed)
- **Purpose-Based Naming:**
  - **Config:** `.zshrc`, `.vimrc`, `.gitconfig`
  - **Modular:** `.aliases`, `.functions`, `.exports`, `.path`
  - **Standards:** `.editorconfig`, `.gitignore`, `.gitattributes`

### Documentation

- **README.md:** User-facing setup and feature documentation
- **AGENTS.md:** AI development lifecycle and workflow guidelines
- **LICENSE.txt:** Legal information

## Key Files Explained

### scripts/setup.sh

**Purpose:** Main entry point, orchestrates entire setup process
**Responsibilities:**

- Profile selection (personal/work)
- Dependency checks (curl, brew, chmod)
- Make other scripts executable
- Sequential execution of setup scripts
- Success/failure reporting

**Key Functions:**

- `info()` - Cyan informational messages
- `success()` - Green success messages
- `error()` - Red error messages

### scripts/sync.sh

**Purpose:** Copy dotfiles from `src/` to home directory
**Responsibilities:**

- Backup existing files before overwriting
- Copy all `src/.*` files to `~/`
- Generate profile-specific Git configurations
- Reload shell configuration

### scripts/brews.sh

**Purpose:** Install Homebrew CLI packages
**Installed Packages:**

- **Common:** git, node, nvm, zoxide, speedtest-cli, yarn, gh
- **Work Only:** awscli, azure-cli, terraform

**Pattern:** Check if installed → Install if missing → Cleanup

### scripts/casks.sh

**Purpose:** Install GUI applications via Homebrew Cask
**Installed Applications:**

- **Common:** Visual Studio Code
- **Work Only:** Postman, Microsoft Edge, Microsoft Teams, Microsoft OneNote, Slack

### scripts/plugins.sh

**Purpose:** Install Oh My Zsh and plugins
**Installed Components:**

- Oh My Zsh framework
- zsh-autosuggestions
- zsh-syntax-highlighting

### scripts/osx.sh

**Purpose:** Apply macOS system preference tweaks
**Modifications:**

- Disable window animations
- Disable smooth scrolling
- Disable focus ring animations
- Other performance optimizations

### scripts/vscode-extensions.sh

**Purpose:** Install VS Code extensions
**Installed Extensions:**

- ESLint, GitLens, EditorConfig, Prettier
- GitHub Copilot, GitHub Copilot Chat
- YAML support

### src/.zshrc

**Purpose:** Main Zsh configuration
**Contents:**

- Oh My Zsh initialization
- Theme selection (robbyrussell)
- Plugin loading
- Sources modular config files (.path, .exports, .aliases, .functions, .secrets)
- Profile-specific setup

### src/.profile

**Purpose:** User-specific metadata
**Contents:**

- Git author name
- Git author email
- Profile type (personal/work)

**Usage:** Read by scripts to personalize Git configuration

### src/.secrets

**Purpose:** Sensitive environment variables and API keys
**Status:** Gitignored, user-managed
**Usage:** Sourced by `.zshrc` if present

## Data Flow

### Installation Flow

```
User → setup.sh → Profile Selection → $DOTFILES_PROFILE env var
                                      ↓
        brews.sh ← Reads $DOTFILES_PROFILE → Installs packages
        casks.sh ← Reads $DOTFILES_PROFILE → Installs apps
        plugins.sh → Installs Oh My Zsh
        vscode-extensions.sh → Installs extensions
        osx.sh → Tweaks system preferences
        backup.sh → Backs up existing dotfiles
        sync.sh ← Reads .profile + $DOTFILES_PROFILE → Copies dotfiles
                                      ↓
                               User's home directory (~/)
```

### Runtime Flow (After Installation)

```
Terminal Launch → Zsh reads ~/.zshrc
                  ↓
                  Loads Oh My Zsh
                  ↓
                  Sources ~/.path → PATH modifications
                  Sources ~/.exports → Environment variables
                  Sources ~/.aliases → Command shortcuts
                  Sources ~/.functions → Custom functions
                  Sources ~/.secrets → Sensitive vars (if exists)
                  ↓
                  Ready for user interaction
```

## Extension Strategy

### Adding New Scripts

1. Create `scripts/<new-action>.sh`
2. Add shebang: `#!/usr/bin/env zsh`
3. Add error handling: `set -euo pipefail`
4. Define logging functions: `info()`, `success()`, `error()`
5. Make executable: `chmod u+x scripts/<new-action>.sh`
6. Add to `setup.sh` execution sequence
7. Document in README.md

### Adding New Dotfiles

1. Add file to `src/.<filename>`
2. File automatically copied by `sync.sh` (uses globbing)
3. If shell config, source in `.zshrc`
4. Document purpose in README.md

### Adding Profile-Specific Logic

1. Check `$DOTFILES_PROFILE` in script
2. Use conditional logic:
   ```bash
   if [[ "$DOTFILES_PROFILE" == "work" ]]; then
     # work-specific logic
   fi
   ```
3. Update relevant arrays (BREWS, CASKS, etc.)

## Backup and Recovery

### Backup Locations

- **Dotfile Backups:** `~/dotfiles-backup-TIMESTAMP/`
- **Created By:** `backup.sh` before `sync.sh` runs
- **Contents:** All existing dotfiles that would be overwritten

### Recovery Process

1. Locate backup: `ls -la ~/dotfiles-backup-*`
2. Copy desired files back: `cp ~/dotfiles-backup-TIMESTAMP/.zshrc ~/`
3. Restart shell: `exec zsh`

## Testing Locations

### Development Testing

- **Local:** Test scripts in cloned repository before running setup
- **Sandbox:** Test in fresh macOS VM or separate user account
- **Verification:** Check installed packages, dotfile presence, config loading

### Production Usage

- **Target:** User's primary macOS home directory (`~/`)
- **Scope:** System-wide configurations (Homebrew, VS Code, macOS defaults)

## Version Control Strategy

### Tracked Files

- All scripts in `scripts/`
- All dotfiles in `src/` except `.secrets`
- Documentation (README.md, AGENTS.md, LICENSE.txt)
- Terminal theme configuration

### Ignored Files

- `src/.secrets` (sensitive data)
- OS-specific files (`.DS_Store`)
- Editor artifacts (`.vscode/`, `*.swp`)

### Branching

- **Main Branch:** Production-ready configurations
- **Feature Branches:** Test new configurations before merging
- **Personal Forks:** Users can fork and customize for their needs
