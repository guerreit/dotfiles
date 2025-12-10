# Implementation Plan

## Overview

This implementation extends three existing scripts (setup.sh, sync.sh, ssh-key.sh) to complete profile-based configuration management. The work is divided into four major areas: sync enhancements for Git global config, setup orchestration improvements, SSH integration, and comprehensive testing.

## Tasks

- [x] 1. Implement Git global configuration in sync.sh
- [x] 1.1 (P) Add profile determination logic

  - Create helper function to determine active profile from argument or file
  - Priority order: PROFILE_CHOICE argument, then GIT_DEFAULT_ROLE from sourced .gitconfig.roles, then "personal" fallback
  - Return "personal" or "work" string for downstream use
  - _Requirements: 2.3, 2.4, 2.11_

- [x] 1.2 Add global Git config execution function

  - Create function to set git config --global user.name and user.email
  - Use profile determination to select correct GIT*PERSONAL*_ or GIT*WORK*_ variables
  - Execute git config --global commands for name and email
  - Log success message indicating which profile was applied
  - Handle errors with appropriate messaging
  - _Requirements: 2.1, 2.2, 2.5, 4.2, 4.3_

- [x] 1.3 Integrate global config into sync flow

  - Call git global config function after generate_git_configs() succeeds
  - Ensure function only executes if Git config file generation was successful
  - Position call before file copy operations in main sync flow
  - Preserve existing error handling and logging patterns
  - _Requirements: 2.1, 2.2, 2.5_

- [x] 2. Enhance profile persistence in setup.sh
- [x] 2.1 Add profile persistence function

  - Create function to update GIT_DEFAULT_ROLE in src/.gitconfig.roles file
  - Validate that .gitconfig.roles exists before attempting update
  - Use sed for in-place update of GIT_DEFAULT_ROLE line
  - Preserve all other content in file unchanged
  - Handle errors if file missing or update fails
  - _Requirements: 1.3_

- [x] 2.2 Integrate persistence into setup flow

  - Call persistence function immediately after profile selection validation
  - Execute before exporting DOTFILES_PROFILE environment variable
  - Execute before calling any child scripts
  - Ensure profile is written to file before sync.sh reads it
  - _Requirements: 1.3_

- [x] 2.3 (P) Add optional SSH key generation prompt

  - Create prompt asking user if they want to generate SSH keys
  - Display clear message explaining purpose (Git authentication)
  - Default answer to No to avoid forcing generation
  - Execute ssh-key.sh if user confirms
  - Display informational message if user declines
  - Position after profile persistence but before brews.sh
  - _Requirements: 4.1_

- [x] 3. Integrate profile-aware email sourcing in ssh-key.sh
- [x] 3.1 Add email sourcing from configuration file

  - Create function to source src/.gitconfig.roles and extract email variables
  - Extract GIT_PERSONAL_EMAIL and GIT_WORK_EMAIL if sourcing succeeds
  - Fall back to hardcoded defaults if .gitconfig.roles not found or sourcing fails
  - Log warning message if fallback is used
  - Maintain backward compatibility for standalone script execution
  - _Requirements: 3.3, 3.4, 4.1, 4.5_

- [x] 3.2 Replace hardcoded email defaults

  - Update personal and work email variables to use sourced values
  - Set PERSONAL_EMAIL from GIT_PERSONAL_EMAIL or hardcoded fallback
  - Set WORK_EMAIL from GIT_WORK_EMAIL or hardcoded fallback
  - Call sourcing function at top of script before key generation logic
  - Preserve existing key generation, ssh-agent, and config update functionality
  - _Requirements: 3.3, 3.4, 4.1_

- [ ] 4. End-to-end integration and testing
- [ ] 4.1 Test fresh personal profile installation

  - Verify profile prompt displays correctly
  - Confirm profile persists to .gitconfig.roles as "personal"
  - Check DOTFILES_PROFILE environment variable exported
  - Validate git config --global returns personal name and email
  - Ensure conditional includes generated correctly in .gitconfig
  - Test optional SSH key generation with personal email
  - Verify all child scripts execute successfully
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.3, 4.1, 4.2_

- [ ] 4.2 Test fresh work profile installation

  - Verify profile prompt displays correctly
  - Confirm profile persists to .gitconfig.roles as "work"
  - Check DOTFILES_PROFILE environment variable exported
  - Validate git config --global returns work name and email
  - Ensure conditional includes generated correctly in .gitconfig
  - Test declining SSH key generation
  - Verify work-specific packages installed (brews and casks)
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.4, 4.3, 7.2, 7.4_

- [ ] 4.3 Test profile switching via sync

  - Start with existing personal profile installation
  - Run sync.sh with "work" argument
  - Verify GIT_DEFAULT_ROLE updated to "work" in .gitconfig.roles
  - Confirm git config --global updated to work email
  - Validate generated config files reflect new profile
  - Ensure no data loss or corruption of existing configurations
  - _Requirements: 2.5, 2.11, 9.1, 9.2, 9.3_

- [ ] 4.4 Test standalone script execution

  - Execute sync.sh without arguments, verify it reads GIT_DEFAULT_ROLE from file
  - Execute ssh-key.sh standalone, confirm email sourcing with fallback works
  - Verify scripts function independently without setup.sh orchestration
  - Check error handling when .gitconfig.roles missing
  - _Requirements: 2.11, 3.3, 3.4, 4.5_

- [ ] 4.5 Test error conditions and edge cases

  - Invalid profile selection (3, abc, empty input) displays error and exits
  - Missing .gitconfig.roles handled gracefully with appropriate error messages
  - Git config command failures logged and script exits cleanly
  - sed update failures reported with clear messaging
  - Malformed .gitconfig.roles syntax caught by sourcing error handling
  - SSH key generation respects idempotent checks (existing keys not regenerated)
  - _Requirements: 1.4, 2.12, 9.1_

- [ ] 4.6 Test backward compatibility
  - Verify existing installations continue to work without modification
  - Confirm legacy .profile migration still functions correctly
  - Ensure existing .gitconfig.roles files work with new functionality
  - Test that hardcoded SSH key defaults work when .gitconfig.roles unavailable
  - Validate no regressions in existing backup, package installation, or sync operations
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 8.1, 8.2, 8.3, 9.4_

## Requirements Coverage

All 10 requirements with 56 acceptance criteria covered:

- **Requirement 1** (Profile Selection): Tasks 2.1, 2.2, 4.1, 4.2, 4.5
- **Requirement 2** (Git Identity): Tasks 1.1, 1.2, 1.3, 4.1, 4.2, 4.3, 4.4, 4.5
- **Requirement 3** (SSH Keys): Tasks 3.1, 3.2, 4.1, 4.5 (existing functionality + email integration)
- **Requirement 4** (Email Consistency): Tasks 2.3, 3.1, 3.2, 4.1, 4.2, 4.4
- **Requirement 5** (Validation): Existing git-config-status.sh (no changes needed)
- **Requirement 6** (Legacy Migration): Task 4.6 (existing functionality validated)
- **Requirement 7** (Profile Packages): Task 4.2 (existing functionality validated)
- **Requirement 8** (Backup): Task 4.6 (existing functionality validated)
- **Requirement 9** (Idempotency): Tasks 4.3, 4.5, 4.6 (validation of existing + new functionality)
- **Requirement 10** (Template): Existing .gitconfig.roles (no changes needed)

## Implementation Notes

**Execution Order**:

1. Implement core Git config functionality (1.1-1.3) first - highest priority gap
2. Add profile persistence (2.1-2.2) - required for setup flow
3. Integrate SSH email sourcing (3.1-3.2) - completes email consistency
4. Execute comprehensive testing (4.1-4.6) - validates all functionality

**Parallel Opportunities**:

- Tasks 1.1 and 2.1 can be developed in parallel (separate scripts, no shared code)
- Task 2.3 (SSH prompt) is independent and can be built alongside 1.x or 2.x tasks
- Task 3.1 can start as soon as profile persistence design is clear

**Key Integration Points**:

- Task 1.3 depends on 1.2 completion
- Task 2.2 depends on 2.1 completion
- Task 3.2 depends on 3.1 completion
- All testing tasks (4.x) require implementation tasks (1.x-3.x) to be complete
