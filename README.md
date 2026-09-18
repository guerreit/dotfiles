# Dotfiles (ZSH)

A reproducible macOS development environment for both personal and work profiles. One command installs Homebrew tooling, apps, dotfiles, and role-aware Git identities while guarding your existing setup with automatic backups. The tooling is inspired by [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles/) and [paulirish/dotfiles](https://github.com/paulirish/dotfiles/).

## Why These Dotfiles?

- **Profile-aware automation:** Select Personal or Work to install the correct CLI tools, GUI apps, and default Git role.
- **Role-based Git identities:** Repository owners automatically select personal/work commit identities and SSH keys, with directory patterns as a fallback.
- **Safety first:** `backup.sh` plus the `sync.sh` rsync step keep timestamped copies of every dotfile before anything is overwritten.
- **Optional SSH bootstrap:** `setup.sh` can generate separate personal/work SSH keys, install them into the macOS keychain, and drop a curated `~/.ssh/config`.
- **Editor + terminal ready:** Oh My Zsh, Vim + Solarized, VS Code extensions, and a Terminal theme script are included.
- **macOS tuned:** System defaults are updated for a snappier UI, and everything is idempotent so you can rerun scripts as needed.

## Prerequisites

- macOS with Zsh (default since Catalina)
- [Homebrew](https://brew.sh/) pre-installed (required because `setup.sh` checks for `brew` before running `brews.sh`)
- `curl`, `git`, and `chmod` (stock on macOS)
- Visual Studio Code with the `code` CLI on your PATH if you want automatic extension installs

## Quick Start

1. **Clone the repo**

   ```sh
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles
   ```

2. **Review `src/.gitconfig.roles`**
   - Update identities, GitHub/Bitbucket owner lists, directory fallbacks, and the default role.
3. **Customize dotfiles/templates (optional)**
   - Add secrets to `src/.secrets` (gitignored when deployed).
   - Tweak `src/.ssh_config` if your SSH hostnames differ.
   - Keep `src/.profile` for any legacy shell exports, but Git identity now lives in `.gitconfig.roles`.
4. **Run the installer**

   ```sh
   ./dotfiles setup
   ```

   - Pick Personal or Work, confirm the optional SSH-key generation prompt, and watch the tooling install.

5. **Restart your terminal session** so Zsh loads the new configuration.
6. **Verify Git identities** with:

   ```sh
   ./dotfiles status
   ```

7. Re-run `./dotfiles sync [personal|work]` whenever you edit files under `src/`.

## CLI Interface

The `dotfiles` CLI provides a unified interface for all dotfiles operations:

```sh
./dotfiles <command> [options]
```

**Available Commands:**

- `setup` – Complete first-time setup (guided installation)
- `sync [profile]` – Sync dotfiles from src/ to $HOME (profile: personal/work)
- `backup` – Create timestamped backup of existing dotfiles
- `cleanup-backups` – Preview archiving older backups; use `--apply` to execute
- `status` – Show current Git identity and configuration status
- `ssh-keys` – Generate SSH keys for personal and work accounts
- `theme` – Install terminal theme (Solarized Dark)
- `install-brews` – Install Homebrew formulae
- `install-casks` – Install Homebrew casks
- `install-plugins` – Install Oh My Zsh plugins
- `install-vscode` – Install VS Code extensions
- `osx` – Apply macOS system preferences

**Examples:**

```sh
./dotfiles help              # Show all commands
./dotfiles setup             # First-time setup
./dotfiles sync personal     # Sync with personal profile
./dotfiles status            # Check Git identity
./dotfiles backup            # Backup before changes
./dotfiles ssh-keys          # Generate SSH keys
```

> 💡 **Tip:** The CLI is a wrapper around the scripts in `scripts/` directory. You can still run scripts directly if needed (e.g., `./scripts/setup.sh`), but the CLI provides a cleaner, more consistent interface.

## What Setup Does

The `./dotfiles setup` command (or `./scripts/setup.sh` directly) orchestrates the entire flow:

1. Use your profile choice for package and application installation without changing Git identity rules.
2. Optional SSH key generation via `scripts/ssh-key.sh` (personal + work Ed25519 keys, added to the agent and keychain).
3. Ensure `curl`, `brew`, and `chmod` exist, then mark helper scripts executable.
4. Call `scripts/backup.sh` to snapshot existing dotfiles under `~/.dotfiles-backup/<timestamp>`.
5. Install Oh My Zsh, vim-plug, and the Solarized theme through `scripts/plugins.sh`.
6. Install/upgrade CLI tools (`scripts/brews.sh`) and GUI apps (`scripts/casks.sh`) based on the selected profile.
7. Install VS Code extensions with `scripts/vscode-extensions.sh` (skipped if the `code` CLI is missing).
8. Apply macOS UI tweaks (`scripts/osx.sh`).
9. Sync every file under `src/` into `$HOME` with `scripts/sync.sh`, which also:
   - Generates `.gitconfig`, `.gitconfig.personal`, and `.gitconfig.work` from `.gitconfig.roles`
   - Removes any global `user.name`/`user.email` so conditional includes stay authoritative
   - Copies `src/.ssh_config` into `~/.ssh/config` with secure permissions
   - Backs up changed files under `~/.dotfiles-backup/<timestamp>-sync.<id>`
10. Display current status through `scripts/git-config-status.sh` so you can confirm the active identity.

## Role-Aware Git Identities

`src/.gitconfig.roles` is the single source of truth for identities and account routing. A minimal example:

```bash
GIT_PERSONAL_NAME="Your Name"
GIT_PERSONAL_EMAIL="you@me.com"

GIT_WORK_NAME="Your Name"
GIT_WORK_EMAIL="you@company.com"

GIT_PERSONAL_GITHUB_OWNERS=("personal-user")
GIT_WORK_GITHUB_OWNERS=("work-user" "CompanyOrg")
GIT_WORK_BITBUCKET_OWNERS=("company-workspace")

GIT_WORK_PATTERNS=(
  "~/work/**"
  "~/clients/**"
)

GIT_DEFAULT_ROLE="personal"
```

After editing the file, run `./dotfiles sync` to regenerate every Git config artifact. The script:

- Writes `~/.gitconfig.personal` and `~/.gitconfig.work`
- Rebuilds the `includeIf` section inside `~/.gitconfig`
- Rewrites known GitHub owners to `github.com-personal` or `github.com-work`
- Wipes any lingering global `user.*` settings that would override conditional includes
- Validates the generated files before copying them into `$HOME`

Rules are evaluated whenever Git reads a repository configuration; cloning a
new repository does not modify `~/.gitconfig`. One `CompanyOrg` entry covers
every current and future `CompanyOrg/*` repository. Add an owner only when you
begin working with a genuinely new organization.

Use `./dotfiles status --dry-run` anytime to see which pattern would match the current directory, confirm the expected identity, and verify all files exist.

> **Profiles vs roles**
> _Profiles_ drive package/app installation. _Roles_ determine Git identity and SSH authentication. Setup deliberately keeps them independent.

## Feature Breakdown

### Homebrew CLI Packages

- Common: `git`, `node`, `nvm`, `zoxide`, `speedtest-cli`, `yarn`, `gh`
- Work profile adds: `awscli`, `azure-cli`, `terraform`

### Homebrew Casks

- Common: Visual Studio Code
- Work profile adds: Postman, Microsoft Edge, Microsoft Teams, Microsoft OneNote, Slack

### Shell & Vim

- Oh My Zsh with your preferred theme + plugins
- Modular dotfiles (`.aliases`, `.exports`, `.functions`, `.path`, `.secrets`)
- vim-plug plus Solarized Dark, stored under `~/.vim/colors/`

### VS Code Extensions

`scripts/vscode-extensions.sh` guarantees the following extensions are installed (and skips anything already present):

- `dbaeumer.vscode-eslint`
- `eamodio.gitlens`
- `editorconfig.editorconfig`
- `esbenp.prettier-vscode`
- `github.copilot`
- `github.copilot-chat`
- `redhat.vscode-yaml`

### macOS Tweaks

`scripts/osx.sh` disables window animations, smooth scrolling, and focus-ring animations for a faster UI. Changes may require logout/restart.

### SSH & Terminal Theme

- `scripts/ssh-key.sh` creates two Ed25519 keys, adds them to the macOS keychain, and installs the checked-in SSH template.
- `src/.ssh_config` is copied to `~/.ssh/config` with strict permissions; edit it in `src/` to customize host aliases.
- Plain `github.com` is personal-only; generated URL rewrites route configured work owners through `github.com-work`.
- `scripts/terminal-theme.sh` downloads the Solarized Dark Terminal profile, prompts you to set it as the default, and adjusts font + window sizing via AppleScript.

### Dotfile Sync

- `scripts/sync.sh` uses checksum-based `rsync`; unchanged files do not generate backups, even if their timestamps change.
- `.DS_Store`, `.git`, and `.gitignore` are excluded. The root `.ssh_config` is handled separately; `.gitconfig.roles` stays in the repo.
- Changed files are backed up under `~/.dotfiles-backup/<timestamp>-sync.<id>`. Empty backup directories are removed.

## Managed Dotfiles (src/)

- `.zshrc`, `.aliases`, `.exports`, `.functions`, `.path`
- `.vimrc`, `.editorconfig`
- `.gitconfig` (template), `.gitconfig.roles`, `.gitconfig.personal`, `.gitconfig.work`
- `.gitignore`, `.gitattributes`, `.stCommitMsg`
- `.profile` (legacy metadata), `.hushlogin`
- `.ssh_config`

`src/.secrets` is machine-local and ignored by Git. `sync.sh` deploys it when present; never commit secrets to this repository.

## Supporting Scripts

All scripts can be run directly or through the `./dotfiles` CLI (recommended):

- `scripts/setup.sh` (or `./dotfiles setup`) – main entry point for full installation
- `scripts/sync.sh` (or `./dotfiles sync`) – rsync deployment + Git config generation
- `scripts/backup.sh` (or `./dotfiles backup`) – manual backup helper (also invoked automatically)
- `scripts/cleanup-backups.sh` (or `./dotfiles cleanup-backups`) – preview-first backup retention
- `scripts/git-config-status.sh` (or `./dotfiles status`) – validate role-aware Git configuration
- `scripts/ssh-key.sh` (or `./dotfiles ssh-keys`) – SSH key bootstrap
- `scripts/brews.sh` (or `./dotfiles install-brews`) – Homebrew formulae installer
- `scripts/casks.sh` (or `./dotfiles install-casks`) – Homebrew casks installer
- `scripts/plugins.sh` (or `./dotfiles install-plugins`) – Oh My Zsh + Vim plugins
- `scripts/vscode-extensions.sh` (or `./dotfiles install-vscode`) – VS Code extensions
- `scripts/osx.sh` (or `./dotfiles osx`) – macOS defaults tweaks
- `scripts/terminal-theme.sh` (or `./dotfiles theme`) – Terminal profile importer

> 💡 **CLI vs Direct Scripts:** The `dotfiles` CLI provides better error handling, consistent output, and a cleaner interface. Direct script execution is still supported for advanced use cases.

## Safety Nets & Recovery

- Full snapshots use `~/.dotfiles-backup/<timestamp>-snapshot.<id>`; older timestamp-only snapshots are also recognized.
- Sync backups use `~/.dotfiles-backup/<timestamp>-sync.<id>`. Unique IDs prevent same-second collisions, and new backup directories are private.
- Cleanup keeps the newest five backups **of each kind** by default. Full snapshots and incremental sync backups have separate retention counts; sync backups are not full restore points.
- Cleanup is manual and previews by default. No scheduled or automatic deletion is installed.
- Only recognized timestamped entries inside `~/.dotfiles-backup` are eligible. Symlinks, unrelated entries, and legacy `~/.dotfiles_backup_*` directories are left alone.

```sh
./dotfiles cleanup-backups                         # Preview archive of older backups
./dotfiles cleanup-backups --keep 5 --apply          # Archive older backups, keeping five per kind
./dotfiles cleanup-backups --delete --keep 5        # Preview permanent deletion instead
./dotfiles cleanup-backups --delete --keep 5 --apply # Permanently delete older backups
./dotfiles cleanup-backups --archives --delete --keep 5       # Preview archive pruning
./dotfiles cleanup-backups --archives --delete --keep 5 --apply
```

Archives live in `~/.dotfiles-backup/archives/`. Compression and archive integrity checks must succeed before the original directory is removed. Existing archives are never overwritten. Archives accumulate until explicitly pruned with `--archives --delete`; deleting them is permanent. `--keep` must be at least 1.

To restore, inspect an archive with `tar -tzf <archive.tar.gz>`, extract it into a separate directory with `tar -xzf <archive.tar.gz> -C <restore-directory>`, then copy only the files you need into `$HOME`. Uncompressed backups can be inspected and copied directly. Restart your shell after restoring shell configuration.

Run the isolated regression checks with `zsh tests/backups.zsh`; they use temporary home directories, never your real configuration.

## Credits

- Inspired by [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles/) and [paulirish/dotfiles](https://github.com/paulirish/dotfiles/)

Feel free to fork and adapt for your own workflow!
