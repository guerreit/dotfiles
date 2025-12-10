# Requirements Document

## Project Description (Input)

automated git config based role i.e personal or work

## Introduction

The git-config-role feature will automate Git configuration management based on user role context (personal vs work). Currently, the dotfiles repository uses a manual profile selection during setup that exports `$DOTFILES_PROFILE`, and `.profile` contains basic role detection logic. This feature will enhance the system to automatically detect the appropriate role context and apply corresponding Git configurations (user.name, user.email) without requiring manual intervention or environment variable exports.

## Requirements

### Requirement 1: Automatic Role Detection

**Objective:** As a developer, I want the system to automatically detect whether I'm in a personal or work context, so that I don't have to manually specify my profile every time.

#### Acceptance Criteria

1. When a Git repository is accessed, the Git Config System shall determine the appropriate role (personal or work) based on configurable detection rules
2. When repository path matches work-related patterns (e.g., contains `/work/`, `/clients/`, company name), the Git Config System shall classify the context as "work"
3. When hostname contains work-related keywords (e.g., "work", "corp", company name), the Git Config System shall classify the context as "work"
4. When environment variable `WORK_PROFILE` is set, the Git Config System shall classify the context as "work"
5. When none of the work indicators are present, the Git Config System shall default to "personal" context
6. The Git Config System shall support user-configurable detection rules through a configuration file

### Requirement 2: Role-Based Git Configuration

**Objective:** As a developer, I want my Git user name and email to be automatically set based on the detected role, so that my commits always have the correct author information.

#### Acceptance Criteria

1. When role is detected as "personal", the Git Config System shall apply personal Git configuration (user.name and user.email from personal profile)
2. When role is detected as "work", the Git Config System shall apply work Git configuration (user.name and user.email from work profile)
3. The Git Config System shall support per-repository Git configuration overrides using Git's conditional includes
4. When Git configuration is applied, the Git Config System shall preserve existing Git aliases and settings from `.gitconfig`
5. The Git Config System shall store role-specific configurations in separate files (`.gitconfig.personal` and `.gitconfig.work`)

### Requirement 3: Configuration Management

**Objective:** As a developer, I want to easily manage my personal and work Git identities, so that I can update them without editing scripts.

#### Acceptance Criteria

1. The Git Config System shall read role-specific Git configurations from a centralized configuration file
2. When user updates personal Git identity (name/email), the Git Config System shall apply changes to all personal repositories on next access
3. When user updates work Git identity (name/email), the Git Config System shall apply changes to all work repositories on next access
4. The Git Config System shall support a configuration file format that is human-readable and editable (e.g., JSON, YAML, or shell-sourceable)
5. If configuration file is missing, the Git Config System shall create a default configuration with placeholder values and notify the user

### Requirement 4: Setup Integration

**Objective:** As a developer setting up my environment, I want the git-config-role feature to be integrated into the existing setup process, so that it works seamlessly with my dotfiles.

#### Acceptance Criteria

1. When `setup.sh` runs, the Git Config System shall initialize role-based Git configuration structure
2. The Git Config System shall integrate with the existing profile selection mechanism in `setup.sh`
3. When `sync.sh` runs, the Git Config System shall synchronize role-specific Git configuration files to the home directory
4. The Git Config System shall preserve backward compatibility with existing `.profile` and `.gitconfig` files
5. When setup completes, the Git Config System shall display the active Git configuration (name and email) to the user

### Requirement 5: Directory-Based Configuration

**Objective:** As a developer with organized directory structures, I want to configure specific directories to always use a particular role, so that I can override automatic detection when needed.

#### Acceptance Criteria

1. The Git Config System shall support directory-based Git configuration using Git's conditional includes (`includeIf "gitdir:path"`)
2. When user specifies a directory path for a role, the Git Config System shall configure Git to use that role's identity for all repositories under that path
3. The Git Config System shall allow multiple directory patterns for each role (e.g., `~/work/**`, `~/clients/**` for work role)
4. When directory-based rule conflicts with automatic detection, the Git Config System shall prioritize the directory-based rule
5. The Git Config System shall support wildcards and glob patterns in directory path specifications

### Requirement 6: Validation and Feedback

**Objective:** As a developer, I want to verify which Git configuration is active in my current context, so that I can ensure my commits will have the correct author information.

#### Acceptance Criteria

1. The Git Config System shall provide a command or script to display the currently active Git configuration
2. When queried, the Git Config System shall show the detected role, active user.name, and active user.email
3. When queried, the Git Config System shall indicate which detection rule triggered the role selection
4. If Git configuration is incomplete or invalid, the Git Config System shall display a warning message with remediation steps
5. The Git Config System shall support a dry-run mode to preview configuration changes without applying them

### Requirement 7: Error Handling and Fallbacks

**Objective:** As a developer, I want the system to handle configuration errors gracefully, so that my development workflow is not disrupted.

#### Acceptance Criteria

1. If role-specific configuration file is missing, the Git Config System shall fall back to global Git configuration
2. If Git commands fail during configuration, the Git Config System shall log error details and continue with existing configuration
3. When configuration file contains invalid syntax, the Git Config System shall display error message with line number and continue with default values
4. If both personal and work configurations are missing, the Git Config System shall prompt user to initialize configurations
5. The Git Config System shall never leave Git in an unconfigured state (user.name and user.email must always be set)
