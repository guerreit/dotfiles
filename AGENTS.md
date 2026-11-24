# AGENTS.md

macOS dotfiles for two machines (personal and work): `src/` holds the dotfiles, `scripts/` installs and deploys them into `$HOME`, and `./dotfiles` is the CLI wrapper over `scripts/`. README.md is the user-facing manual; GLOSSARY.md defines the domain terms.

## Verify every change

```sh
zsh tests/run.zsh
```

This is the same check CI runs: `zsh -n` on every script, then the backup and Git identity regression suites. The suites point `HOME` at a temp directory, so they are safe to run anywhere. A change is done when this passes.

## Your `$HOME` is production

This repo is checked out on the machine it configures. These commands write to the real `$HOME`, Homebrew, macOS defaults, or SSH keys, so leave them for the user to run: `setup`, `sync`, `backup`, `ssh-keys`, `theme`, `osx`, `install-*`, and `cleanup-backups --apply`. To exercise them, copy the pattern in `tests/backups.zsh`: export a sandbox `HOME` (and `GIT_CONFIG_GLOBAL`), copy `scripts/` and `src/` into it, and run from there.

Read-only commands are fine to run: `./dotfiles status --dry-run`, `./dotfiles cleanup-backups` (previews by default), `./dotfiles help`.

`src/.secrets` is machine-local and gitignored. Never read it or commit it.

## How deployment works

- Edit files in `src/`, never their copies in `$HOME`. `scripts/sync.sh` deploys them with checksum `rsync` and backs up anything it overwrites to `~/.dotfiles-backup/<timestamp>-sync.<id>`.
- `sync.sh` excludes `.gitconfig.roles` (it generates configs but stays in the repo) and `.ssh_config` (copied separately to `~/.ssh/config` with mode 600).
- `sync.sh <profile>` rewrites `GIT_DEFAULT_ROLE` in the tracked `src/.gitconfig.roles`. Expect that diff after a profile sync.

## Git identity

- `src/.gitconfig.roles` is the single source of truth: identities, GitHub/Bitbucket owner lists, directory patterns, default role.
- `scripts/git-identity.zsh` is the shared resolver, sourced by `sync.sh` and `git-config-status.sh`. Precedence: remote owner, then directory pattern (`GIT_WORK_PATTERNS`), then `GIT_DEFAULT_ROLE`. Change resolution logic there, not in the callers, and cover it in `tests/git-identity.zsh`.
- `render_git_identity_configs` in `git-identity.zsh` turns a loaded roles file into `.gitconfig.personal`, `.gitconfig.work` and `.gitconfig.role-rules`. `sync.sh` renders them into a temp staging folder, validates them, and deploys them in the same rsync as `src/`; generated files never land in the repo. Rule order in the role rules is significant (later rules win).
- `src/.gitconfig` is hand-written and ends with `[include] path = ~/.gitconfig.role-rules`. Sync refuses to run if it sets `user.name` / `user.email`.
- Rendering is checked byte for byte against `tests/fixtures/git-role-rules/expected/`. After an intended output change, re-render the fixture roles file into that folder and review the diff.
- A **profile** (what setup installs) and a **role** (which identity a repo commits with) are independent; keep them separate in code and prose.

## Shell conventions

- Zsh, not bash: `#!/usr/bin/env zsh` and `set -euo pipefail`. Zsh arrays are 1-indexed.
- Locate the script with `"$(dirname "${(%):-%x}")"`, as the existing scripts do.
- Log through the per-script helpers `info`, `success`, `error`, `warning`, defined with `print -P "%F{color}[TAG]%f $1"`.
- Quote every expansion and use `[[ ]]` for tests.
- Keep scripts idempotent: check for an existing install, file, or symlink before acting, and back up before overwriting.
- Profile-specific packages go in `scripts/brews.sh` / `scripts/casks.sh` behind `[[ "$DOTFILES_PROFILE" == "work" ]]`. `setup.sh` exports `DOTFILES_PROFILE`; the child scripts depend on it.

## Adding a script or command

1. Create `scripts/<name>.sh` and `chmod u+x` it (`./dotfiles` refuses non-executable scripts).
2. Wire it into the `case` in `./dotfiles` and its `show_help` text.
3. Call it from `scripts/setup.sh` if it belongs in first-time install.
4. Add it to README.md under "Supporting Scripts" and the CLI command list.
