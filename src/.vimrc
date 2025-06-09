" Set shortmess to keep messages short and avoid unnecessary prompts
set shortmess=at

" Enable Vim features not available in Vi
set nocompatible

" Plugin management
call plug#begin('~/.vim/plugged')
" Add your plugins here
" Plug 'preservim/nerdtree'           " File tree explorer
" Plug 'junegunn/fzf.vim'            " Fuzzy finder
" Plug 'tpope/vim-fugitive'          " Git integration
" Plug 'airblade/vim-gitgutter'      " Git diff in the gutter
Plug 'altercation/vim-colors-solarized'  " Solarized color scheme
call plug#end()

" File type handling
filetype plugin indent on

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
set ignorecase          " Case-insensitive search
set smartcase           " Case-sensitive when uppercase is used
set gdefault            " Always use /g flag for search/replace

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

" Performance optimizations
set lazyredraw          " Don't redraw while executing macros
set ttyfast             " Faster terminal connection
set updatetime=300      " Faster update time for gitgutter and other plugins

" Quality of life improvements
set mouse=a             " Enable mouse support
set clipboard=unnamed   " Use system clipboard
set scrolloff=5         " Keep 5 lines above/below cursor
set sidescrolloff=5     " Keep 5 characters left/right of cursor

" Backup and undo settings
set backup
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set undodir=~/.vim/undo//
set undofile

" Visual improvements
set termguicolors       " Enable true colors if your terminal supports it
colorscheme solarized   " Solarized color scheme
set background=dark     " Use dark background

" Custom highlight settings to match Solarized
@REM highlight Search ctermfg=black ctermbg=yellow guifg=#002b36 guibg=#b58900
@REM highlight IncSearch ctermfg=black ctermbg=yellow guifg=#002b36 guibg=#b58900
@REM highlight CursorLine ctermbg=236 guibg=#073642
@REM highlight Visual ctermbg=236 guibg=#073642
@REM highlight MatchParen ctermfg=black ctermbg=yellow guifg=#002b36 guibg=#b58900

" Status line enhancement
set laststatus=2
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [POS=%l,%v][%p%%]

" Use space as leader
let mapleader=" "

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Clear search highlighting
nnoremap <leader><CR> :nohlsearch<CR>

" Auto commands
" Return to last edit position when opening files
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" End of vimrc
