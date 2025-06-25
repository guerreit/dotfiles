# Git user config
GIT_AUTHOR_NAME="Garrett Jones"

# Determine if this is a work or personal profile
# You can customize this logic based on your needs:
# - Check for specific directories, environment variables, or hostnames
# - Set PROFILE_TYPE environment variable in your shell config
if [[ -n "$WORK_PROFILE" ]] || [[ "$HOSTNAME" == *"work"* ]] || [[ "$PWD" == *"work"* ]]; then
    # Work profile
    GIT_AUTHOR_EMAIL="garrettj@slalom.com"
else
    # Personal profile - replace with your personal email
    GIT_AUTHOR_EMAIL="garrettjones@me.com"
fi

GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
git config --global user.name "$GIT_AUTHOR_NAME"

GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git config --global user.email "$GIT_AUTHOR_EMAIL"

echo "Git configured with: $GIT_AUTHOR_NAME <$GIT_AUTHOR_EMAIL>"
