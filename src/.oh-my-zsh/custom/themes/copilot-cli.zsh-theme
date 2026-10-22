# Copilot CLI-inspired Oh My Zsh theme.
# Focuses on cool blue/cyan accents and a minimal two-line prompt.

setopt prompt_subst

local exit_segment='%(?..%F{red}[%?]%f )'

PROMPT='${exit_segment}%F{blue}%~%f$(git_prompt_info)
%F{cyan}>%f '

RPROMPT='%F{242}%*%f'

ZSH_THEME_GIT_PROMPT_PREFIX=' %F{magenta}git:(%f'
ZSH_THEME_GIT_PROMPT_SUFFIX='%F{magenta})%f'
ZSH_THEME_GIT_PROMPT_DIRTY='%F{yellow}*%f'
ZSH_THEME_GIT_PROMPT_CLEAN=''
