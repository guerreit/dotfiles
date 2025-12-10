# Implementation Plan

## Overview

This implementation plan breaks down the git-config-role feature into logical, incremental tasks. Tasks are sequenced to build core functionality first, then add migration support, validation tools, and integration.

## Implementation Tasks

- [ ] 1. Create role configuration file structure
- [ ] 1.1 (P) Create .gitconfig.roles template

  - Define shell-sourceable format with personal and work identity variables
  - Include work directory pattern array with example patterns
  - Add default role configuration variable
  - Include comprehensive comments explaining each section and customization
  - _Requirements: 3.1, 3.4_

- [ ] 1.2 (P) Create .gitconfig.personal template

  - Define Git config format with user.name and user.email sections
  - Include comment header explaining file purpose and generation
  - _Requirements: 2.1, 2.5_

- [ ] 1.3 (P) Create .gitconfig.work template

  - Define Git config format with user.name and user.email sections
  - Include comment header explaining file purpose and generation
  - _Requirements: 2.2, 2.5_

- [ ] 2. Enhance sync.sh with configuration generation
- [ ] 2.1 Add Git version validation

  - Check Git version is >= 2.13 for includeIf support
  - Display warning and fallback instructions if version too old
  - Log version check result
  - _Requirements: 7.1, 7.5_

- [ ] 2.2 Implement .gitconfig.roles loading and validation

  - Source .gitconfig.roles file or create from template if missing
  - Validate required variables are set (name, email for both roles)
  - Check work patterns array is defined and non-empty
  - Handle syntax errors with clear error messages and line numbers
  - Create default configuration with placeholder values if file missing
  - _Requirements: 3.1, 3.4, 3.5, 7.3, 7.4_

- [ ] 2.3 Build .gitconfig generation with conditional includes

  - Read existing .gitconfig from src/ to preserve aliases and settings
  - Generate includeIf directives for each work directory pattern
  - Add work pattern includes before default personal include
  - Include comment warnings about auto-generation
  - Write generated .gitconfig to src/ directory
  - _Requirements: 2.3, 2.4, 5.1, 5.2, 5.3, 5.4_

- [ ] 2.4 (P) Build .gitconfig.personal generation

  - Read personal identity variables from .gitconfig.roles
  - Generate user.name and user.email sections
  - Write to src/.gitconfig.personal
  - _Requirements: 2.1, 3.2_

- [ ] 2.5 (P) Build .gitconfig.work generation

  - Read work identity variables from .gitconfig.roles
  - Generate user.name and user.email sections
  - Write to src/.gitconfig.work
  - _Requirements: 2.2, 3.3_

- [ ] 2.6 Add generated config validation

  - Test generated .gitconfig syntax with git config --list
  - Verify includeIf directives are valid
  - Check that personal and work configs have required fields
  - Abort sync if validation fails and display specific errors
  - _Requirements: 7.2, 7.5_

- [ ] 3. Implement legacy configuration migration
- [ ] 3.1 Detect legacy .profile git configuration

  - Check if ~/.profile exists and contains GIT_AUTHOR_NAME or GIT_AUTHOR_EMAIL
  - Parse profile content to determine if migration is needed
  - Log detection result
  - _Requirements: 4.4_

- [ ] 3.2 Extract configuration from legacy .profile

  - Parse GIT_AUTHOR_NAME value
  - Parse personal email from GIT_AUTHOR_EMAIL (personal branch)
  - Parse work email from GIT_AUTHOR_EMAIL (work branch)
  - Extract any existing work detection patterns if present
  - Handle parsing failures gracefully with warnings
  - _Requirements: 4.4, 7.3_

- [ ] 3.3 Generate .gitconfig.roles from extracted values

  - Create .gitconfig.roles with extracted personal/work identities
  - Use extracted patterns or default patterns for work directories
  - Validate extracted values are non-empty before generation
  - _Requirements: 3.2, 4.3_

- [ ] 3.4 Preserve legacy configuration with deprecation notice

  - Backup original .profile to .profile.backup with timestamp
  - Prepend deprecation comment block to .profile
  - Log migration actions for user review
  - _Requirements: 4.4_

- [ ] 4. Create git configuration status script
- [ ] 4.1 Implement current configuration detection

  - Query git config user.name and user.email
  - Determine active role from config values
  - Detect current working directory context
  - _Requirements: 6.1, 6.2_

- [ ] 4.2 Build pattern matching analysis

  - Read work patterns from .gitconfig.roles
  - Test current directory against each pattern
  - Identify which pattern matched (if any)
  - Show detection method used (directory, environment, default)
  - _Requirements: 6.3_

- [ ] 4.3 Implement configuration validation checks

  - Verify all required config files exist
  - Check .gitconfig syntax is valid
  - Validate includeIf directives are correctly formatted
  - Detect common misconfigurations (empty values, invalid paths)
  - _Requirements: 6.4_

- [ ] 4.4 Build status output formatter

  - Display active name and email
  - Show detected role and matching pattern
  - List all configured work patterns
  - Present validation results with clear status indicators
  - Provide actionable remediation steps for issues found
  - Support dry-run mode for testing patterns without execution
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 5. Integrate with setup.sh
- [ ] 5.1 Update setup.sh to initialize git-config-role

  - Ensure sync.sh is called with git config generation enabled
  - Display git configuration status after sync completes
  - Log any migration actions performed
  - _Requirements: 4.1, 4.5_

- [ ] 5.2 Make git-config-status.sh executable

  - Add to chmod commands in setup.sh
  - Ensure script has proper shebang and permissions
  - _Requirements: 4.1_

- [ ] 6. Testing and validation
- [ ] 6.1 Test fresh installation flow

  - Run setup.sh on system without existing git config
  - Verify .gitconfig.roles created with template values
  - Confirm all git config files generated correctly
  - Validate git config --list shows expected configuration
  - _Requirements: 4.1, 4.2, 4.5, 7.5_

- [ ] 6.2 Test migration from legacy .profile

  - Create test .profile with git configuration
  - Run sync.sh and verify migration extracts values correctly
  - Confirm .gitconfig.roles contains extracted identities
  - Validate legacy .profile backed up with deprecation notice
  - _Requirements: 4.3, 4.4, 7.3_

- [ ] 6.3 Test role detection in different directory contexts

  - Create test repositories under work patterns (~/work/, ~/clients/)
  - Create test repositories under personal paths
  - Run git config user.email in each context
  - Verify correct role applied based on directory location
  - Test git commit author resolution
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 5.1, 5.2, 5.3, 5.4_

- [ ] 6.4 Test configuration customization workflow

  - Edit .gitconfig.roles with custom patterns and identities
  - Run sync.sh to regenerate configs
  - Verify changes reflected in generated files
  - Test pattern matching with new patterns
  - _Requirements: 3.2, 3.3, 5.5_

- [ ] 6.5 Test git-config-status.sh validation

  - Run status script in various directory contexts
  - Verify output shows correct active configuration
  - Test detection of configuration issues (missing files, invalid syntax)
  - Validate remediation suggestions are helpful
  - Test dry-run mode
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 6.6 Test error handling scenarios

  - Test with Git version < 2.13
  - Test with invalid .gitconfig.roles syntax
  - Test with missing configuration files
  - Test with empty name or email values
  - Verify appropriate error messages and fallbacks
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 7. Documentation updates
- [ ] 7.1 (P) Update README.md

  - Add git-config-role feature to features list
  - Explain automatic role detection and configuration
  - Document .gitconfig.roles customization
  - Add git-config-status.sh usage instructions
  - Update profile system section with new approach
  - _Requirements: 4.5, 6.1_

- [ ] 7.2 (P) Add inline documentation to scripts
  - Add comprehensive comments to sync.sh enhancements
  - Document git-config-status.sh functions and usage
  - Include examples in .gitconfig.roles template
  - _Requirements: 3.4, 6.4_
