" .vimrc

" !silent is used to suppress error messages if the config line
" references plugins/colorschemes that might be missing

" Enable syntax highlighting
syntax enable

" Set 256 color terminal support
set t_Co=256

" Show the cursor line and column number
set ruler
" Show partial commands in status line
set showcmd
" Show whether in insert or replace mode
set showmode

" Searching
" search as characters are entered
set incsearch
" highlight matches
set hlsearch

" Show a list of possible completions
set wildmenu

" No line wrapping
set nowrap
" Use 2 spaces for indentation
set shiftwidth=2
" Use 2 spaces for soft tab
set softtabstop=2
" Use 2 spaces for tab
set tabstop=2
" Expand tab to spaces
set expandtab
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

