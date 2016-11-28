" .vimrc

execute pathogen#infect()
syntax on
filetype plugin indent on
syntax enable

" Make Vim more useful
set nocompatible
" Show the filename in the window titlebar
set title
" Show the cursor line and column number
set ruler
" Show partial commands in status line
set showcmd
" Show whether in insert or replace mode
set showmode
" Use 2 spaces for indentation
set shiftwidth=2
" Use 2 spaces for soft tab
set softtabstop=2
" Use 2 spaces for tab
set tabstop=2
" Expand tab to spaces
set expandtab

" Use relative line numbers
if exists("&relativenumber")
set relativenumber
  au BufReadPost * set relativenumber
endif

" Searching
set incsearch
" highlight matches
set hlsearch
" Show a list of possible completions
set wildmenu
" Enable line numbers
set number
" Highlight current line
set cursorline
" Don’t reset cursor to start of line when moving around.
set nostartofline

" Show 'invisible' characters
set list
" Set characters used to indicate 'invisible' characters
set listchars=tab:▸\
set listchars+=trail:·
set listchars+=nbsp:_

" Centralize backups, swapfiles and undo history
set backupdir=$HOME/.vim/backups
set directory=$HOME/.vim/swaps
if exists("&undodir")
  set undodir=$HOME/.vim/undo
endif
set viminfo+=n$HOME/.vim/.viminfo
