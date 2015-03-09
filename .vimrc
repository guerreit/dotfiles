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

" Always show status line
set laststatus=2
" Broken down into easily includeable segments
" Filename
set statusline=%<%f\
" Options
set statusline+=%w%h%m%r
" Current dir
set statusline+=\ [%{getcwd()}]
" Right aligned file nav info
set statusline+=%=%-14.(%l,%c%V%)\ %p%%

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
" Start scrolling three lines before the horizontal window border
set scrolloff=3
" Don’t reset cursor to start of line when moving around.
set nostartofline

" Show 'invisible' characters
set list
" Set characters used to indicate 'invisible' characters
set listchars=tab:▸\
set listchars+=trail:·
set listchars+=nbsp:_
"set listchars+=eol:¬

" Centralize backups, swapfiles and undo history
set backupdir=$HOME/.vim/backups
set directory=$HOME/.vim/swaps
if exists("&undodir")
    set undodir=$HOME/.vim/undo
endif
set viminfo+=n$HOME/.vim/.viminfo

" Faster viewport scrolling (3 lines at a time)
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>
vnoremap <C-e> 3<C-e>
vnoremap <C-y> 3<C-y>
