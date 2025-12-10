# Requirements Document

## Project Description (Input)

ensure correct profile information, personal or private, gets configured all the way through -- ssh keys, git config. anything thats specific to a particular profile

## Introduction

This specification defines comprehensive profile-based configuration management for the dotfiles system. The goal is to ensure all profile-specific settings (personal vs. work identities) are consistently applied across Git configuration, SSH keys, and any other profile-dependent components throughout the entire setup and maintenance lifecycle.

## Requirements

### Requirement 1: Profile Selection and Persistence

**Objective:** As a developer, I want to select my profile once during setup, so that all subsequent configurations automatically use the correct profile-specific settings.

#### Acceptance Criteria

1. When user runs `setup.sh`, the Setup System shall prompt for profile selection (personal or work)
2. When user selects a profile, the Setup System shall export `DOTFILES_PROFILE` environment variable to all child scripts
3. When profile is selected, the Setup System shall persist the profile choice in `.gitconfig.roles` for future sync operations
4. If profile selection is invalid, then the Setup System shall display error message and exit with non-zero status
5. The Setup System shall pass the selected profile to all configuration scripts that require profile-specific behavior

### Requirement 2: Git Identity Configuration

**Objective:** As a developer, I want my Git commits to automatically use the correct identity based on repository location, so that I don't accidentally commit with the wrong email address.

#### Acceptance Criteria

1. When profile is selected during setup, the Setup System shall execute `git config --global user.name` with profile-specific name from `.gitconfig.roles`
2. When profile is selected during setup, the Setup System shall execute `git config --global user.email` with profile-specific email from `.gitconfig.roles`
3. When profile is "personal", the Setup System shall set global Git config using `GIT_PERSONAL_NAME` and `GIT_PERSONAL_EMAIL` values
4. When profile is "work", the Setup System shall set global Git config using `GIT_WORK_NAME` and `GIT_WORK_EMAIL` values
5. When `sync.sh` runs with profile argument, the Sync System shall update global Git config to match the specified profile
6. When `.gitconfig.roles` is updated, the Sync System shall generate `.gitconfig.personal` with personal name and email
7. When `.gitconfig.roles` is updated, the Sync System shall generate `.gitconfig.work` with work name and email
8. When `.gitconfig.roles` defines work directory patterns, the Sync System shall generate conditional `includeIf` sections in main `.gitconfig`
9. While user is in a directory matching work patterns, Git shall use work identity for commits (overriding global config via conditional includes)
10. While user is in a directory not matching work patterns, Git shall use personal identity based on default role setting
11. When `GIT_DEFAULT_ROLE` is set in `.gitconfig.roles`, the Sync System shall apply that as the fallback identity
12. If `.gitconfig.roles` is missing required variables, then the Sync System shall display error message with missing variable names
13. If Git version is below 2.13, then the Sync System shall warn about lack of conditional include support and use global configuration fallback only

### Requirement 3: SSH Key Management

**Objective:** As a developer, I want separate SSH keys for personal and work profiles, so that I can securely authenticate with different accounts on the same services.

#### Acceptance Criteria

1. When `ssh-key.sh` is executed, the SSH Key System shall check for existing personal SSH key (`id_ed25519_github_personal`)
2. When `ssh-key.sh` is executed, the SSH Key System shall check for existing work SSH key (`id_ed25519_github_work`)
3. If personal SSH key does not exist, then the SSH Key System shall generate ED25519 key pair with personal email as comment
4. If work SSH key does not exist, then the SSH Key System shall generate ED25519 key pair with work email as comment
5. When SSH keys are generated, the SSH Key System shall add both keys to ssh-agent
6. When SSH keys are generated, the SSH Key System shall create or update SSH config file with host-based key selection rules
7. If SSH directory does not exist, then the SSH Key System shall create `~/.ssh` with 700 permissions

### Requirement 4: Profile-Specific Email Configuration

**Objective:** As a developer, I want profile selection to determine which email addresses are used throughout all configuration files, so that personal and work identities remain separate.

#### Acceptance Criteria

1. When profile is selected, the Setup System shall use corresponding email for SSH key generation
2. When profile is "personal", the Setup System shall configure Git with personal email from `.gitconfig.roles`
3. When profile is "work", the Setup System shall configure Git with work email from `.gitconfig.roles`
4. When `.gitconfig.roles` is updated, the Sync System shall regenerate all profile-specific Git configuration files
5. The System shall ensure email consistency between SSH key comments and Git user configuration

### Requirement 5: Configuration Validation and Status

**Objective:** As a developer, I want to verify my current Git configuration, so that I can confirm the correct identity is active for my current location.

#### Acceptance Criteria

1. When `git-config-status.sh` is executed, the Git Status System shall display current global Git user name and email
2. When `git-config-status.sh` is executed, the Git Status System shall show which identity would be used in current directory
3. When current directory matches work pattern, the Git Status System shall indicate work identity is active
4. When current directory does not match work patterns, the Git Status System shall indicate personal identity is active based on default role
5. The Git Status System shall list all configured work directory patterns from `.gitconfig.roles`
6. If `.gitconfig.roles` is missing, then the Git Status System shall warn user about missing role configuration

### Requirement 6: Legacy Configuration Migration

**Objective:** As a developer with existing legacy configuration in `.profile`, I want automatic migration to the new role-based system, so that I don't lose my existing Git identity settings.

#### Acceptance Criteria

1. When sync runs and `.profile` contains legacy `GIT_AUTHOR_NAME`, the Sync System shall extract name value
2. When sync runs and `.profile` contains legacy `GIT_AUTHOR_EMAIL`, the Sync System shall extract personal and work email values
3. When legacy configuration is detected, the Sync System shall update `.gitconfig.roles` with extracted values
4. When legacy configuration is migrated, the Sync System shall create backup of original `.profile`
5. When legacy configuration is migrated, the Sync System shall add deprecation notice to `.profile` directing users to new system
6. After migration completes, the Sync System shall display success message indicating completion

### Requirement 7: Profile-Specific Package Installation

**Objective:** As a developer, I want different sets of tools installed based on my profile selection, so that I only have work-specific tools on my work machines.

#### Acceptance Criteria

1. When profile is "personal", the Package System shall install common CLI packages only
2. When profile is "work", the Package System shall install common CLI packages plus work-specific packages (awscli, azure-cli, terraform)
3. When profile is "personal", the Package System shall install VS Code as only GUI application
4. When profile is "work", the Package System shall install VS Code plus work-specific GUI applications (Postman, Microsoft Edge, Teams, OneNote, Slack)
5. When package installation is skipped due to profile, the Package System shall log informational message about profile-based filtering

### Requirement 8: Configuration File Backup

**Objective:** As a developer, I want automatic backups before any configuration changes, so that I can recover if something goes wrong.

#### Acceptance Criteria

1. When `sync.sh` is executed, the Backup System shall create timestamped backup directory (`~/.dotfiles_backup_YYYYMMDDHHMMSS`)
2. When backing up, the Backup System shall copy all existing dotfiles from home directory to backup directory
3. When backup completes, the Backup System shall log success message with backup location
4. If backup fails, then the Sync System shall abort before making any changes
5. The Backup System shall preserve file permissions during backup operations

### Requirement 9: Sync Operation Idempotency

**Objective:** As a developer, I want to run sync multiple times safely, so that I can update configurations without fear of breaking my system.

#### Acceptance Criteria

1. When `sync.sh` runs multiple times, the Sync System shall produce consistent results
2. When regenerating Git configuration files, the Sync System shall overwrite previous generated files
3. When copying dotfiles to home directory, the Sync System shall overwrite existing files (after backup)
4. The Sync System shall preserve custom edits in `.gitconfig.roles` between sync runs
5. The Sync System shall update `updated_at` timestamp in generated configuration file headers

### Requirement 10: Profile Configuration Template

**Objective:** As a developer, I want clear documentation and defaults in `.gitconfig.roles`, so that I can easily customize profile settings.

#### Acceptance Criteria

1. The `.gitconfig.roles` file shall include inline comments explaining each configuration section
2. The `.gitconfig.roles` file shall provide example work directory patterns with wildcard documentation
3. The `.gitconfig.roles` file shall define separate name/email variables for personal and work identities
4. The `.gitconfig.roles` file shall define configurable array of work directory patterns with globstar support
5. The `.gitconfig.roles` file shall define `GIT_DEFAULT_ROLE` setting with recommended value documented
6. When `.gitconfig.roles` is missing, the Sync System shall use template defaults without failing
