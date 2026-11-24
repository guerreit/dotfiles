#!/usr/bin/env zsh
#
# Git identity module: everything a Git role means.
#
#   load_git_identity_config <roles-file>    load roles and apply defaults
#   resolve_git_identity <git-dir> [url...]  predict the role git will apply
#   render_git_identity_configs <out-dir>    write the generated Git config
#   git_role_rules_support                   check git can apply role rules
#   git_identity_dead_patterns               list patterns git can never match
#
# Both the renderer and the resolver walk one ordered rule list
# (_build_git_role_rules), so the rules git is given and the role status
# predicts cannot drift apart.

typeset -g GIT_ROLE_RULES_MIN_VERSION="2.36"

# Loads the tracked roles file, then the machine-local default role from
# <roles-file>.local if present. Only GIT_DEFAULT_ROLE is read from the local
# file: identities, owners and patterns stay single-sourced in the tracked one.
# Args:
#   $1 - tracked roles file
# Sets:
#   GIT_DEFAULT_ROLE         personal | work (personal when unset)
#   GIT_DEFAULT_ROLE_SOURCE  file name the default came from, or "built-in"
# Returns:
#   non-zero if a file fails to load or the default role is not personal/work
#   (message on stderr)
load_git_identity_config() {
  local roles_file="$1"
  local local_file="${1}.local"
  local source_status=0 local_role extra

  typeset -g GIT_DEFAULT_ROLE_SOURCE="built-in"
  if [[ -f "$roles_file" ]]; then
    source "$roles_file" 2>/dev/null || source_status=$?
    (( ${+GIT_DEFAULT_ROLE} )) && GIT_DEFAULT_ROLE_SOURCE="${roles_file:t}"
  fi

  if (( source_status == 0 )) && [[ -f "$local_file" ]]; then
    extra="$(grep -E '^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=' "$local_file" |
      grep -vE '^[[:space:]]*(export[[:space:]]+)?GIT_DEFAULT_ROLE=' || true)"
    [[ -z "$extra" ]] ||
      print -u2 -- "Ignoring settings other than GIT_DEFAULT_ROLE in ${local_file:t}; they belong in ${roles_file:t}"
    if local_role="$(zsh -c 'source "$1" >/dev/null 2>&1 || exit 1; print -r -- "${GIT_DEFAULT_ROLE-}"' _ "$local_file")"; then
      if [[ -n "$local_role" ]]; then
        typeset -g GIT_DEFAULT_ROLE="$local_role"
        GIT_DEFAULT_ROLE_SOURCE="${local_file:t}"
      fi
    else
      print -u2 -- "Failed to load ${local_file:t}"
      source_status=1
    fi
  fi

  if [[ -n "${GIT_DEFAULT_ROLE:-}" && "$GIT_DEFAULT_ROLE" != personal && "$GIT_DEFAULT_ROLE" != work ]]; then
    print -u2 -- "GIT_DEFAULT_ROLE must be personal or work, not '$GIT_DEFAULT_ROLE' (from $GIT_DEFAULT_ROLE_SOURCE)"
    (( source_status )) || source_status=1
  fi
  typeset -g GIT_DEFAULT_ROLE="${GIT_DEFAULT_ROLE:-personal}"

  (( ${+GIT_PERSONAL_GITHUB_OWNERS} )) || typeset -ga GIT_PERSONAL_GITHUB_OWNERS=()
  (( ${+GIT_WORK_GITHUB_OWNERS} )) || typeset -ga GIT_WORK_GITHUB_OWNERS=()
  (( ${+GIT_WORK_BITBUCKET_OWNERS} )) || typeset -ga GIT_WORK_BITBUCKET_OWNERS=()
  (( ${+GIT_WORK_PATTERNS} )) || typeset -ga GIT_WORK_PATTERNS=()
  (( ${+GIT_PERSONAL_SSH_ALIASES} )) || typeset -ga GIT_PERSONAL_SSH_ALIASES=("github.com-personal" "github.com-guerreit")
  (( ${+GIT_WORK_SSH_ALIASES} )) || typeset -ga GIT_WORK_SSH_ALIASES=("github.com-work" "github.com-garrettj-slalom")
  return "$source_status"
}

# Predicts the role git will apply, using git's own matching rules:
# owner rules are case-sensitive, directory rules case-insensitive, all
# remotes count, and the last matching rule wins.
# Args:
#   $1    - absolute .git folder, or "" outside a repository
#   $2... - raw remote URLs (as configured, before insteadOf); the first one
#           decides GIT_IDENTITY_SSH_ALIAS
# Sets (always, every one):
#   GIT_IDENTITY_ROLE              personal | work
#   GIT_IDENTITY_NAME / _EMAIL     identity configured for that role
#   GIT_IDENTITY_DETECTION_METHOD  "Default role" | "Directory fallback" | "Remote owner"
#   GIT_IDENTITY_MATCHED_RULE      includeIf condition that won, or ""
#   GIT_IDENTITY_MATCHED_PATTERN   roles-file pattern that won, or "none"
#   GIT_IDENTITY_MATCHED_OWNER     host/owner that won, or "none"
#   GIT_IDENTITY_SSH_ALIAS         SSH alias the first remote is routed through, or ""
#   GIT_IDENTITY_CASE_HINT         explanation when a remote matches an owner
#                                  only if case is ignored, or ""
resolve_git_identity() {
  local git_dir="$1"
  shift
  local -a remotes=("$@")
  local rule kind condition role label pattern url
  local -a fields git_dirs

  typeset -g GIT_IDENTITY_ROLE="personal"
  typeset -g GIT_IDENTITY_DETECTION_METHOD="Default role"
  typeset -g GIT_IDENTITY_MATCHED_RULE=""
  typeset -g GIT_IDENTITY_MATCHED_PATTERN="none"
  typeset -g GIT_IDENTITY_MATCHED_OWNER="none"
  typeset -g GIT_IDENTITY_SSH_ALIAS=""
  typeset -g GIT_IDENTITY_CASE_HINT=""

  # git tries the .git path both as given and with symlinks resolved.
  if [[ -n "$git_dir" ]]; then
    git_dirs=("$git_dir")
    [[ "${git_dir:A}" != "$git_dir" ]] && git_dirs+=("${git_dir:A}")
  fi

  _build_git_role_rules
  for rule in "${GIT_ROLE_RULES[@]}"; do
    fields=("${(@ps:\t:)rule}")
    kind="${fields[1]}" condition="${fields[2]:-}" role="${fields[3]:-}" label="${fields[4]:-}"
    case "$kind" in
      default)
        GIT_IDENTITY_ROLE="$role"
        ;;
      gitdir)
        pattern="$(_git_gitdir_pattern "${condition#gitdir/i:}")"
        for url in "${git_dirs[@]}"; do
          if _git_wildmatch "$pattern" "$url" nocase ||
             _git_wildmatch "$(_git_realpath_pattern "$pattern")" "$url" nocase; then
            GIT_IDENTITY_ROLE="$role"
            GIT_IDENTITY_DETECTION_METHOD="Directory fallback"
            GIT_IDENTITY_MATCHED_RULE="$condition"
            GIT_IDENTITY_MATCHED_PATTERN="$label"
            break
          fi
        done
        ;;
      remote)
        pattern="${condition#hasconfig:remote.*.url:}"
        for url in "${remotes[@]}"; do
          if _git_wildmatch "$pattern" "$url"; then
            GIT_IDENTITY_ROLE="$role"
            GIT_IDENTITY_DETECTION_METHOD="Remote owner"
            GIT_IDENTITY_MATCHED_RULE="$condition"
            GIT_IDENTITY_MATCHED_OWNER="$label"
            break
          elif [[ -z "$GIT_IDENTITY_CASE_HINT" ]] && _git_wildmatch "$pattern" "$url" nocase; then
            GIT_IDENTITY_CASE_HINT="remote $url matches the $role owner ${label#*/} only if case is ignored; git applies owner rules case-sensitively, so fix the URL or add that spelling to .gitconfig.roles"
          fi
        done
        ;;
    esac
  done

  # A hint only explains a remote that fell through to a fallback.
  [[ "$GIT_IDENTITY_DETECTION_METHOD" == "Remote owner" ]] && GIT_IDENTITY_CASE_HINT=""
  _resolve_git_ssh_alias "${remotes[1]:-}"

  if [[ "$GIT_IDENTITY_ROLE" == "work" ]]; then
    typeset -g GIT_IDENTITY_NAME="${GIT_WORK_NAME:-}" GIT_IDENTITY_EMAIL="${GIT_WORK_EMAIL:-}"
  else
    typeset -g GIT_IDENTITY_NAME="${GIT_PERSONAL_NAME:-}" GIT_IDENTITY_EMAIL="${GIT_PERSONAL_EMAIL:-}"
  fi
}

# Writes the generated Git config for the loaded roles file into a folder:
#   .gitconfig.personal / .gitconfig.work  [user] identity per Git role
#   .gitconfig.role-rules                   url rewrites and include rules that
#                                           select a Git role per repository
# ~/.gitconfig includes .gitconfig.role-rules last. Rule order is significant:
# git applies later includes over earlier ones, so remote-owner rules come last.
# Args:
#   $1 - existing output folder
# Returns:
#   0 on success, 1 if a required identity is missing (message on stderr)
render_git_identity_configs() {
  local out_dir="$1"
  local var

  for var in GIT_PERSONAL_NAME GIT_PERSONAL_EMAIL GIT_WORK_NAME GIT_WORK_EMAIL; do
    if [[ -z "${(P)var:-}" ]]; then
      print -u2 -- "$var must be set in .gitconfig.roles"
      return 1
    fi
  done

  _render_git_role_identity personal "$GIT_PERSONAL_NAME" "$GIT_PERSONAL_EMAIL" \
    > "$out_dir/.gitconfig.personal"
  _render_git_role_identity work "$GIT_WORK_NAME" "$GIT_WORK_EMAIL" \
    > "$out_dir/.gitconfig.work"
  _render_git_role_rules > "$out_dir/.gitconfig.role-rules"
}

# Returns 0 if git can apply role rules, 1 if git is older than
# GIT_ROLE_RULES_MIN_VERSION, 2 if git is missing. Sets GIT_VERSION_FOUND.
git_role_rules_support() {
  typeset -g GIT_VERSION_FOUND=""
  GIT_VERSION_FOUND="$(git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)" || true
  [[ -n "$GIT_VERSION_FOUND" ]] || return 2

  local major="${GIT_VERSION_FOUND%%.*}" minor="${GIT_VERSION_FOUND#*.}"
  local min_major="${GIT_ROLE_RULES_MIN_VERSION%%.*}" min_minor="${GIT_ROLE_RULES_MIN_VERSION#*.}"
  (( major > min_major || (major == min_major && minor >= min_minor) )) || return 1
}

# Prints each GIT_WORK_PATTERNS entry git can never match. git compares
# gitdir patterns with the repository's .git folder, so a pattern must end
# in "/" or "/**" (everything below) or name a .git folder.
git_identity_dead_patterns() {
  local pattern rendered
  for pattern in "${GIT_WORK_PATTERNS[@]}"; do
    rendered="$(_git_gitdir_pattern "$(_git_role_dir_pattern "$pattern")")"
    [[ "$rendered" == *'**' || "$rendered" == *'.git' ]] || print -r -- "$pattern"
  done
}

# --- internals ---------------------------------------------------------------

# Roles-file directory pattern -> the pattern written into gitdir/i:.
# "dir/**" becomes "dir/", which git matches recursively.
_git_role_dir_pattern() {
  local pattern="$1"
  [[ "$pattern" == *"/**" ]] && pattern="${pattern%/**}/"
  print -r -- "$pattern"
}

# gitdir pattern -> the full pattern git matches, per git-config(1):
# "~/" expands to HOME, a pattern not starting with "~/", "./" or "/" gets
# "**/" prepended, and a trailing "/" gets "**" appended.
_git_gitdir_pattern() {
  local pattern="$1"
  if [[ "$pattern" == "~/"* ]]; then
    pattern="$HOME/${pattern#\~/}"
  elif [[ "$pattern" != /* && "$pattern" != ./* ]]; then
    pattern="**/$pattern"
  fi
  [[ "$pattern" == */ ]] && pattern="${pattern}**"
  print -r -- "$pattern"
}

# Like git, also match with symlinks resolved in the pattern's literal
# leading folders (e.g. macOS /var -> /private/var).
_git_realpath_pattern() {
  local pattern="$1"
  local prefix="${pattern%%[*?\[]*}"
  local dir="${prefix%/*}"
  if [[ -n "$dir" && -d "$dir" ]]; then
    pattern="${dir:A}${pattern#"$dir"}"
  fi
  print -r -- "$pattern"
}

# git wildmatch with WM_PATHNAME: "*" and "?" stop at "/", "**/" spans zero
# or more folders, a trailing "**" matches everything.
# Args: $1 pattern, $2 subject, $3 "nocase" for case-insensitive
_git_wildmatch() {
  local subject="$2" zpattern="" rest="$1"
  setopt localoptions extendedglob
  # nocasematch only affects =~ in zsh; globs need the (#i) flag.
  [[ "${3:-}" == "nocase" ]] && zpattern="(#i)"

  while [[ -n "$rest" ]]; do
    case "$rest" in
      '**/'*) zpattern+='(*/|)'; rest="${rest:3}" ;;
      '**'*)  zpattern+='*'; rest="${rest:2}" ;;
      '*'*)   zpattern+='[^/]#'; rest="${rest:1}" ;;
      '?'*)   zpattern+='[^/]'; rest="${rest:1}" ;;
      *)      zpattern+="${(q)rest[1]}"; rest="${rest:1}" ;;
    esac
  done
  [[ "$subject" == ${~zpattern} ]]
}

# Mirrors the url.*.insteadOf rules: the alias a remote is routed through.
_resolve_git_ssh_alias() {
  local url="$1" rule kind alias owner
  local -a fields

  if [[ "$url" == git@github.com-*:* ]]; then
    url="${url#git@}"
    GIT_IDENTITY_SSH_ALIAS="${url%%:*}"
    return 0
  fi

  for rule in "${GIT_ROLE_RULES[@]}"; do
    fields=("${(@ps:\t:)rule}")
    [[ "${fields[1]}" == "url" ]] || continue
    alias="${fields[2]}" owner="${fields[3]}"
    if [[ "$url" == "git@github.com:$owner/"* || "$url" == "https://github.com/$owner/"* ]]; then
      GIT_IDENTITY_SSH_ALIAS="$alias"
      return 0
    fi
  done
}

# Builds GIT_ROLE_RULES: the ordered rules for the loaded roles file. Each
# entry is tab-separated:
#   section <title>                      comment heading
#   gap                                  blank line
#   url     <ssh-alias> <owner>          GitHub insteadOf rewrite
#   default -          <role>            unconditional include
#   gitdir  <condition> <role> <pattern> directory include
#   remote  <condition> <role> <owner>   remote-owner include
_build_git_role_rules() {
  local t=$'\t' owner pattern remote_pattern ssh_alias
  local default_role="personal"
  [[ "${GIT_DEFAULT_ROLE:-}" == "work" ]] && default_role="work"
  typeset -ga GIT_ROLE_RULES=()

  if (( ${#GIT_PERSONAL_GITHUB_OWNERS[@]} > 0 )); then
    GIT_ROLE_RULES+=("section${t}Personal GitHub owner routing")
    for owner in "${GIT_PERSONAL_GITHUB_OWNERS[@]}"; do
      GIT_ROLE_RULES+=("url${t}github.com-personal${t}$owner")
    done
    GIT_ROLE_RULES+=("gap")
  fi

  if (( ${#GIT_WORK_GITHUB_OWNERS[@]} > 0 )); then
    GIT_ROLE_RULES+=("section${t}Work GitHub owner routing")
    for owner in "${GIT_WORK_GITHUB_OWNERS[@]}"; do
      GIT_ROLE_RULES+=("url${t}github.com-work${t}$owner")
    done
    GIT_ROLE_RULES+=("gap")
  fi

  # The default comes first so the more specific rules below override it.
  GIT_ROLE_RULES+=("section${t}Default identity fallback" "default${t}-${t}$default_role" "gap")

  if (( ${#GIT_WORK_PATTERNS[@]} > 0 )); then
    GIT_ROLE_RULES+=("section${t}Work directory fallbacks")
    for pattern in "${GIT_WORK_PATTERNS[@]}"; do
      GIT_ROLE_RULES+=("gitdir${t}gitdir/i:$(_git_role_dir_pattern "$pattern")${t}work${t}$pattern")
    done
    GIT_ROLE_RULES+=("gap")
  fi

  if (( ${#GIT_PERSONAL_GITHUB_OWNERS[@]} > 0 )); then
    GIT_ROLE_RULES+=("section${t}Personal GitHub identity rules")
    for owner in "${GIT_PERSONAL_GITHUB_OWNERS[@]}"; do
      for remote_pattern in "git@github.com:$owner/**" "https://github.com/$owner/**"; do
        GIT_ROLE_RULES+=("remote${t}hasconfig:remote.*.url:$remote_pattern${t}personal${t}github.com/$owner")
      done
      for ssh_alias in "${GIT_PERSONAL_SSH_ALIASES[@]}"; do
        GIT_ROLE_RULES+=("remote${t}hasconfig:remote.*.url:git@$ssh_alias:$owner/**${t}personal${t}github.com/$owner")
      done
    done
  fi

  if (( ${#GIT_WORK_GITHUB_OWNERS[@]} > 0 )); then
    GIT_ROLE_RULES+=("section${t}Work GitHub identity rules")
    for owner in "${GIT_WORK_GITHUB_OWNERS[@]}"; do
      for remote_pattern in "git@github.com:$owner/**" "https://github.com/$owner/**"; do
        GIT_ROLE_RULES+=("remote${t}hasconfig:remote.*.url:$remote_pattern${t}work${t}github.com/$owner")
      done
      for ssh_alias in "${GIT_WORK_SSH_ALIASES[@]}"; do
        GIT_ROLE_RULES+=("remote${t}hasconfig:remote.*.url:git@$ssh_alias:$owner/**${t}work${t}github.com/$owner")
      done
    done
  fi

  if (( ${#GIT_WORK_BITBUCKET_OWNERS[@]} > 0 )); then
    GIT_ROLE_RULES+=("section${t}Work Bitbucket identity rules")
    for owner in "${GIT_WORK_BITBUCKET_OWNERS[@]}"; do
      for remote_pattern in "git@bitbucket.org:$owner/**" "https://bitbucket.org/$owner/**"; do
        GIT_ROLE_RULES+=("remote${t}hasconfig:remote.*.url:$remote_pattern${t}work${t}bitbucket.org/$owner")
      done
    done
  fi
}

_render_git_role_identity() {
  local role="$1" name="$2" email="$3"
  local title="${(C)role}"

  print -r -- "# ~/.gitconfig.$role - $title Git Identity"
  print -r -- "# Generated by sync.sh from src/.gitconfig.roles. Do not edit; edits are overwritten."
  print -r -- ""
  print -r -- "[user]"
  print -r -- $'\t'"name = $name"
  print -r -- $'\t'"email = $email"
}

_render_git_role_rules() {
  local rule
  local -a fields

  print -r -- "# ~/.gitconfig.role-rules - Git role rules"
  print -r -- "# Generated by sync.sh from src/.gitconfig.roles. Do not edit; edits are overwritten."
  print -r -- "# Remote-owner rules are last so they take precedence over directory fallbacks."
  print -r -- ""

  _build_git_role_rules
  for rule in "${GIT_ROLE_RULES[@]}"; do
    fields=("${(@ps:\t:)rule}")
    case "${fields[1]}" in
      section) print -r -- "# ${fields[2]}" ;;
      gap)     print -r -- "" ;;
      url)
        print -r -- "[url \"git@${fields[2]}:${fields[3]}/\"]"
        print -r -- $'\t'"insteadOf = git@github.com:${fields[3]}/"
        print -r -- $'\t'"insteadOf = https://github.com/${fields[3]}/"
        ;;
      default)
        print -r -- "[include]"
        print -r -- $'\t'"path = ~/.gitconfig.${fields[3]}"
        ;;
      gitdir|remote)
        print -r -- "[includeIf \"${fields[2]}\"]"
        print -r -- $'\t'"path = ~/.gitconfig.${fields[3]}"
        ;;
    esac
  done
}
