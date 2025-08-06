# Git user config
GIT_AUTHOR_NAME="Garrett Jones"

# Determine if this is a work or personal profile
# Use DOTFILES_PROFILE if set, otherwise fall back to environment detection
if [[ "$DOTFILES_PROFILE" == "work" ]] || [[ -n "$WORK_PROFILE" ]] || [[ "$HOSTNAME" == *"work"* ]] || [[ "$PWD" == *"work"* ]]; then
    # Work profile
    GIT_AUTHOR_EMAIL="garrettj@slalom.com"
    PROFILE_TYPE="work"
else
    # Personal profile - replace with your personal email
    GIT_AUTHOR_EMAIL="garrettjones@me.com"
    PROFILE_TYPE="personal"
fi

GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
git config --global user.name "$GIT_AUTHOR_NAME"

GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git config --global user.email "$GIT_AUTHOR_EMAIL"

# Only show the message if DOTFILES_PROFILE is set (during setup)
if [[ -n "$DOTFILES_PROFILE" ]]; then
    echo "Git configured with: $GIT_AUTHOR_NAME <$GIT_AUTHOR_EMAIL>"
fi
