# 1. Installation profile and Git role are independent

Date: 2026-11-24

## Status

Accepted

## Context

Setup asks for an **installation profile** (personal or work), which decides the Homebrew packages and apps a machine gets. Separately, each repository commits with a **Git role** (personal or work), chosen by owner and directory rules, with `GIT_DEFAULT_ROLE` as the fallback when no rule matches.

`sync.sh` used to take the profile as an argument and write it into `GIT_DEFAULT_ROLE` in the tracked `src/.gitconfig.roles`. That coupled the two concepts the glossary defines as separate, and because one tracked roles file serves every machine, machines set up with different profiles kept rewriting it, leaving a diff in the repository after every profile sync.

The default role can legitimately differ per machine (a work laptop may want scratch repositories to default to work), but nothing about it depends on which packages are installed.

## Decision

- The installation profile never sets or changes the Git role.
- `sync.sh` takes no profile argument and never edits tracked files.
- A machine's default role lives in `src/.gitconfig.roles.local`, which is gitignored and never deployed. Only `GIT_DEFAULT_ROLE` is read from it; identities, owners and directory patterns stay in the tracked roles file. When the local file is absent, the tracked value applies.
- Setup asks for the default role as its own question, suggesting the machine's current default rather than the profile.
- `GIT_DEFAULT_ROLE` must be `personal` or `work`; anything else stops sync.

## Consequences

- Sync can run on any machine without leaving a diff in the repository.
- The default role is visible in `dotfiles status` together with the file it came from.
- `./dotfiles sync personal` and `./dotfiles sync work` now fail with a message pointing at the local file.
- Re-coupling the two (for example, deriving the default role from the profile at sync time) would bring back the per-machine conflict and is out of bounds without revisiting this record.
