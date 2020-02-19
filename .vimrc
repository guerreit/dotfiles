set nocompatible
set title
set ruler
set showcmd
set showmode
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab

syntax on

if exists("&relativenumber")
set relativenumber
  au BufReadPost * set relativenumber
endif

set incsearch
set hlsearch
set wildmenu
set number
set cursorline
set nostartofline

set list
set listchars=tab:▸\
set listchars+=trail:·
set listchars+=nbsp:_

set backupdir=$HOME/.vim/backups
set directory=$HOME/.vim/swaps
if exists("&undodir")
  set undodir=$HOME/.vim/undo
endif
set viminfo+=n$HOME/.vim/.viminfo
