# Dotfiles

Terms for configuring dotfiles and selecting Git identity across repositories.

## Git identity

The name and email attached to commits made in a repository.

## Git role

A personal or work classification that selects a Git identity for a repository.

## Role rules

The generated Git config rules that select a Git role for a repository from its remote owner or directory. Rendered from the roles file into `~/.gitconfig.role-rules`.

## Snapshot

A full restore point: a backup of every dotfile the repository manages, taken by `backup.sh`, by setup, and before every restore.

## Sync backup

A partial backup holding only the files a change was about to overwrite, written by sync and SSH key setup. Restoring one brings back only those files.

## Installation profile

A personal or work choice that selects which tools and applications the setup process installs. It is separate from the Git role used for a particular repository.
