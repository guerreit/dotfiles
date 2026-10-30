#!/usr/bin/env zsh

load_git_identity_config() {
  local roles_file="$1"
  local source_status=0

  if [[ -f "$roles_file" ]]; then
    source "$roles_file" 2>/dev/null || source_status=$?
  fi

  (( ${+GIT_PERSONAL_GITHUB_OWNERS} )) || typeset -ga GIT_PERSONAL_GITHUB_OWNERS=()
  (( ${+GIT_WORK_GITHUB_OWNERS} )) || typeset -ga GIT_WORK_GITHUB_OWNERS=()
  (( ${+GIT_WORK_BITBUCKET_OWNERS} )) || typeset -ga GIT_WORK_BITBUCKET_OWNERS=()
  (( ${+GIT_WORK_PATTERNS} )) || typeset -ga GIT_WORK_PATTERNS=()
  (( ${+GIT_PERSONAL_SSH_ALIASES} )) || typeset -ga GIT_PERSONAL_SSH_ALIASES=("github.com-personal" "github.com-guerreit")
  (( ${+GIT_WORK_SSH_ALIASES} )) || typeset -ga GIT_WORK_SSH_ALIASES=("github.com-work" "github.com-garrettj-slalom")
  return "$source_status"
}

resolve_git_identity() {
  local current_dir="$1"
  local raw_remote="$2"
  local pattern expanded_pattern owner ssh_alias

  GIT_IDENTITY_ROLE="${GIT_DEFAULT_ROLE:-personal}"
  GIT_IDENTITY_MATCHED_PATTERN="none"
  GIT_IDENTITY_MATCHED_OWNER="none"
  GIT_IDENTITY_SSH_ALIAS=""
  GIT_IDENTITY_DETECTION_METHOD="Default role"

  setopt localoptions nocasematch
  for pattern in "${GIT_WORK_PATTERNS[@]}"; do
    expanded_pattern="${pattern/#\~/$HOME}"
    if [[ "$current_dir" == ${~expanded_pattern} ]]; then
      GIT_IDENTITY_MATCHED_PATTERN="$pattern"
      GIT_IDENTITY_ROLE="work"
      GIT_IDENTITY_DETECTION_METHOD="Directory fallback"
      break
    fi
  done

  for owner in "${GIT_PERSONAL_GITHUB_OWNERS[@]}"; do
    if [[ "$raw_remote" == "git@github.com:$owner/"* || "$raw_remote" == "https://github.com/$owner/"* ]]; then
      GIT_IDENTITY_ROLE="personal"
      GIT_IDENTITY_MATCHED_OWNER="github.com/$owner"
      GIT_IDENTITY_SSH_ALIAS="github.com-personal"
      break
    fi

    for ssh_alias in "${GIT_PERSONAL_SSH_ALIASES[@]}"; do
      if [[ "$raw_remote" == "git@$ssh_alias:$owner/"* ]]; then
        GIT_IDENTITY_ROLE="personal"
        GIT_IDENTITY_MATCHED_OWNER="github.com/$owner"
        GIT_IDENTITY_SSH_ALIAS="$ssh_alias"
        break
      fi
    done

    if [[ "$GIT_IDENTITY_MATCHED_OWNER" != "none" ]]; then
      break
    fi
  done

  for owner in "${GIT_WORK_GITHUB_OWNERS[@]}"; do
    if [[ "$raw_remote" == "git@github.com:$owner/"* || "$raw_remote" == "https://github.com/$owner/"* ]]; then
      GIT_IDENTITY_ROLE="work"
      GIT_IDENTITY_MATCHED_OWNER="github.com/$owner"
      GIT_IDENTITY_SSH_ALIAS="github.com-work"
      break
    fi

    for ssh_alias in "${GIT_WORK_SSH_ALIASES[@]}"; do
      if [[ "$raw_remote" == "git@$ssh_alias:$owner/"* ]]; then
        GIT_IDENTITY_ROLE="work"
        GIT_IDENTITY_MATCHED_OWNER="github.com/$owner"
        GIT_IDENTITY_SSH_ALIAS="$ssh_alias"
        break
      fi
    done

    if [[ "$GIT_IDENTITY_MATCHED_OWNER" != "none" ]]; then
      break
    fi
  done

  for owner in "${GIT_WORK_BITBUCKET_OWNERS[@]}"; do
    if [[ "$raw_remote" == "git@bitbucket.org:$owner/"* ||
          "$raw_remote" == "https://bitbucket.org/$owner/"* ]]; then
      GIT_IDENTITY_ROLE="work"
      GIT_IDENTITY_MATCHED_OWNER="bitbucket.org/$owner"
      break
    fi
  done

  if [[ "$GIT_IDENTITY_MATCHED_OWNER" != "none" ]]; then
    GIT_IDENTITY_DETECTION_METHOD="Remote owner"
  fi
}
