#!/usr/bin/env zsh
set -euo pipefail

# Color functions
info() { print -P "%F{cyan}[INFO]%f $1"; }
success() { print -P "%F{green}[SUCCESS]%f $1"; }
error() { print -P "%F{red}[ERROR]%f $1" >&2; }

# Install oh-my-zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || { error "Failed to install oh-my-zsh"; exit 1; }
else
    success "oh-my-zsh is already installed."
fi

# Install vim-plug if not already installed
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    info "Installing vim-plug..."
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || { error "Failed to install vim-plug"; exit 1; }
    success "vim-plug installed successfully."
else
    success "vim-plug is already installed."
fi

# Install Solarized theme if not already installed
if [ ! -d "$HOME/.vim/colors" ]; then
    info "Creating vim colors directory..."
    mkdir -p "$HOME/.vim/colors" || { error "Failed to create colors directory"; exit 1; }
fi

if [ ! -f "$HOME/.vim/colors/solarized.vim" ]; then
    info "Installing Solarized theme..."
    curl -fLo "$HOME/.vim/colors/solarized.vim" \
        https://raw.githubusercontent.com/altercation/vim-colors-solarized/master/colors/solarized.vim || { error "Failed to install Solarized theme"; exit 1; }
    success "Solarized theme installed successfully."
else
    success "Solarized theme is already installed."
fi

success "Plugin installation complete!"
