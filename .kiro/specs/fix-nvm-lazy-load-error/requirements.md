# Requirements Document

## Project Description (Input)

fix this error load-nvmrc:4: command not found: nvm_find_nvmrc when cd'ing into new directory

## Problem Analysis

### Root Cause

The `load-nvmrc()` function in `src/.exports` is triggered automatically on every directory change via `add-zsh-hook chpwd load-nvmrc`. However, this function calls `nvm_find_nvmrc` at line 58, which is an nvm-internal function that only exists after nvm is fully loaded. Due to lazy loading implementation, nvm functions aren't available until the user explicitly calls `nvm`, `node`, `npm`, or `npx`.

### Current Behavior

1. User changes directory with `cd`
2. `chpwd` hook triggers `load-nvmrc()`
3. Function checks `if command -v nvm` (passes because wrapper function exists)
4. Function calls `nvm_find_nvmrc` (fails because nvm.sh hasn't been sourced yet)
5. Error: `load-nvmrc:4: command not found: nvm_find_nvmrc`

### Existing Code Location

- **File:** `src/.exports`
- **Lines:** 54-74 (load-nvmrc function and chpwd hook)
- **Related:** Lines 23-51 (lazy load wrapper functions)

## Requirements

### Functional Requirements

#### FR1: Silent Error Handling

**Priority:** High
**Description:** The `load-nvmrc()` function must handle the case where nvm is not yet fully loaded without displaying errors to the user.

**Acceptance Criteria:**

- No error messages appear when changing directories before nvm is loaded
- Shell remains functional and responsive after directory changes
- Normal shell output is not polluted with error messages

#### FR2: Lazy Load NVM on .nvmrc Detection

**Priority:** High
**Description:** When a `.nvmrc` file is detected during directory change, automatically trigger nvm loading and then switch to the appropriate Node version.

**Acceptance Criteria:**

- If `.nvmrc` exists in new directory and nvm isn't loaded, load nvm automatically
- After loading nvm, apply the Node version specified in `.nvmrc`
- If `.nvmrc` doesn't exist, skip nvm loading (maintain lazy load benefit)
- User sees appropriate feedback when Node version switches

#### FR3: Preserve Lazy Loading Benefits

**Priority:** High
**Description:** Maintain fast shell startup time by only loading nvm when actually needed.

**Acceptance Criteria:**

- Shell startup time remains fast (nvm not loaded on init)
- NVM only loads when explicitly called or when .nvmrc is encountered
- No performance degradation for users who don't use Node in current session

#### FR4: Detect NVM Availability

**Priority:** Medium
**Description:** Reliably detect whether nvm has been fully loaded with all its functions available.

**Acceptance Criteria:**

- Detection works for both lazy-loaded and fully-loaded states
- Check is lightweight and doesn't cause performance issues
- Works consistently across different nvm installation methods (Homebrew, manual)

### Non-Functional Requirements

#### NFR1: Backward Compatibility

**Priority:** High
**Description:** Solution must work with existing nvm installations and not break current workflows.

**Acceptance Criteria:**

- Existing `nvm`, `node`, `npm`, `npx` commands continue to work
- Manual `nvm use` commands work as expected
- `load-nvm` alias in `.aliases` continues to function

#### NFR2: Code Maintainability

**Priority:** Medium
**Description:** Solution should be clear, well-commented, and easy to understand for future maintenance.

**Acceptance Criteria:**

- Function logic is straightforward and documented
- Comments explain why checks are necessary
- Code follows existing style conventions in dotfiles

#### NFR3: Error Recovery

**Priority:** Medium
**Description:** If nvm loading fails for any reason, shell remains usable and provides helpful information.

**Acceptance Criteria:**

- Failed nvm loads don't crash or hang the shell
- User receives clear error messages only when action is required
- Shell continues to function even if nvm is unavailable

### Technical Constraints

1. **Shell Environment:** Must work in Zsh (macOS default)
2. **NVM Installation:** Support Homebrew installation at `/opt/homebrew/opt/nvm/nvm.sh`
3. **Existing Hooks:** Must integrate with `add-zsh-hook chpwd` mechanism
4. **Lazy Loading:** Must preserve lazy loading pattern for startup performance

### Out of Scope

1. Removing lazy loading entirely (would slow shell startup)
2. Supporting shells other than Zsh (Bash, Fish, etc.)
3. Auto-installing nvm if not present
4. Handling multiple simultaneous .nvmrc files in parent directories
5. Caching Node version checks for performance

## Success Metrics

1. **Zero error messages** during normal directory navigation
2. **Automatic version switching** when entering directories with `.nvmrc`
3. **Shell startup time** remains under 1 second (lazy load preserved)
4. **User satisfaction:** No complaints about nvm errors in daily usage
