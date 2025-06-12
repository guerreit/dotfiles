" Basic Vim settings
set nocompatible
set number
set relativenumber
set showcmd
set showmode
set ruler
set cursorline

" Indentation
set expandtab
set shiftwidth=2
set tabstop=2

" Search settings
set incsearch
set hlsearch
set ignorecase
set smartcase

" Visual settings
syntax on
set termguicolors
colorscheme solarized
set background=dark
set cursorline

" Custom highlight for cursor line
highlight CursorLine ctermbg=237 guibg=#0a3c4a

" Quality of life
set mouse=a
set clipboard=unnamed
set scrolloff=5

" Use space as leader
let mapleader=" "

" Basic mappings
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader><CR> :nohlsearch<CR>

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" End of vimrc
