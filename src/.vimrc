" Set shortmess to keep messages short and avoid unnecessary prompts
set shortmess=at

" Enable Vim features not available in Vi
set nocompatible

" Display the filename and status in the terminal title bar
set title

" Show the cursor position, mode, and last entered command
set ruler
set showcmd
set showmode

" Set indentation settings for consistent tabbing and spacing
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab

" Enable syntax highlighting for better code readability
syntax on

" Display line numbers relative to the current line for navigation
set relativenumber
" Automatically set relativenumber for each buffer
au BufReadPost * set relativenumber

" Enhance search functionality with incremental search and highlighting
set incsearch
set hlsearch

" Enable enhanced command-line completion
set wildmenu

" Show line numbers, highlight the current line, and keep cursor in same column
set number
set cursorline
set nostartofline

" Show invisible characters to spot whitespace issues
set list
" Define characters used to represent special whitespace characters
set listchars=tab:▸\
set listchars+=trail:·
set listchars+=nbsp:_

" End of vimrc
