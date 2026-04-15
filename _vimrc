" ============================================================
" _vimrc - Windows Vim Configuration
" ============================================================

" PLUGINS (vim-plug) --------------------------------------------- {{{
" Auto-install vim-plug if not present
let data_dir = expand('~/vimfiles')
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo ' . data_dir . '/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/vimfiles/plugged')

" --- Syntaxe / Highlight ---
Plug 'sheerun/vim-polyglot'                   " Python, C++, PS1, HTML, JS, Java, XML, JSON, CSS...
Plug 'octol/vim-cpp-enhanced-highlight'       " C++ extra
Plug 'pangloss/vim-javascript'                " JS avancé
Plug 'othree/html5.vim'                       " HTML5
Plug 'hail2u/vim-css3-syntax'                 " CSS3
Plug 'elzr/vim-json'                          " JSON + erreurs
Plug 'MaxMEllon/vim-jsx-pretty'               " JSX/TSX React
Plug 'uiiaoo/java-syntax.vim'                 " Java amélioré
Plug 'amadeus/vim-xml'                        " XML/XAML

" --- LSP / Complétion ---
Plug 'prabirshrestha/vim-lsp'                 " Client LSP
Plug 'prabirshrestha/asyncomplete.vim'        " Moteur complétion
Plug 'prabirshrestha/asyncomplete-lsp.vim'    " Bridge LSP <-> asyncomplete
Plug 'mattn/vim-lsp-settings'                 " Auto-config LSP (pyright, clangd, omnisharp, tsserver, lemminx...)

" --- C# / XAML ---
Plug 'OmniSharp/omnisharp-vim'                " C# + XAML complétion/highlight/LSP

" --- HTML / XML / XAML ---
Plug 'alvan/vim-closetag'                     " Fermeture auto balises HTML/XML/XAML
Plug 'mattn/emmet-vim'                        " Expand HTML rapide (div.container<C-y>,)
Plug 'Valloric/MatchTagAlways'                " Surligne balise ouvrante/fermante miroir

" --- Highlight avancé ---
Plug 'luochen1990/rainbow'                    " Parenthèses colorées par niveau
Plug 'RRethy/vim-illuminate'                  " Mot sous curseur surligné
Plug 'nathanaelkane/vim-indent-guides'        " Indentation visuelle
Plug 'airblade/vim-gitgutter'                 " Diff git en marge

" --- Navigation ---
Plug 'preservim/nerdtree'                     " Explorateur fichiers
Plug 'ctrlpvim/ctrlp.vim'                     " Fuzzy finder fichiers
Plug 'preservim/tagbar'                       " Menu fonctions/classes (besoin ctags)
Plug 'liuchengxu/vim-clap', { 'do': ':Clap install-binary!' } " Launcher interactif moderne

" --- Menu interactif ---
Plug 'skywind3000/vim-quickui'                " Menus déroulants style barre de menu

" --- Édition ---
Plug 'tpope/vim-surround'                     " Manipuler quotes/brackets (cs"')
Plug 'tpope/vim-commentary'                   " Commenter gcc / gc
Plug 'jiangmiao/auto-pairs'                   " Fermeture auto brackets/quotes
Plug 'tpope/vim-repeat'                       " Répéter plugins avec .

" --- Interface ---
Plug 'vim-airline/vim-airline'                " Statusline pro
Plug 'vim-airline/vim-airline-themes'         " Thèmes airline

call plug#end()
" }}}

" BASE OPTIONS --------------------------------------------------- {{{
set nocompatible
set encoding=utf-8
set clipboard=unnamed                         " Windows clipboard (unnamed, pas unnamedplus)
set pastetoggle=<F2>                          " Fix: un seul > suffît
set mouse=a

" Affichage
set number
set numberwidth=2
set cursorline
" set cursorcolumn                            " Décommenter si tu veux aussi la colonne
set wrap                                      " Choix: wrap activé (nowrap commenté)
" set nowrap
set scrolloff=10
set showmatch
set showmode
set showcmd
set laststatus=2

" Indentation
set shiftwidth=4
set tabstop=4
set expandtab

" Recherche
set incsearch
set hlsearch
set ignorecase
set smartcase

" Fichiers
set nobackup
set history=1000

" Wildmenu
set wildmenu
set wildmode=list:longest
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" Détection fichiers
filetype on
filetype plugin on
filetype indent on
syntax on
" }}}

" PLUGINS CONFIG ------------------------------------------------- {{{

" --- vim-airline (remplace statusline manuel) ---
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline_theme = 'dark'
let g:airline_powerline_fonts = 0             " Mettre à 1 si tu as une Nerd Font

" --- Rainbow parenthèses ---
let g:rainbow_active = 1

" --- vim-indent-guides ---
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1

" --- NERDTree ---
let NERDTreeShowHidden = 1
let NERDTreeMinimalUI = 1

" --- CtrlP ---
let g:ctrlp_map = '<C-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'

" --- vim-closetag (HTML/XML/XAML) ---
let g:closetag_filenames = '*.html,*.xhtml,*.xml,*.xaml,*.jsx,*.tsx'
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.tsx'

" --- Emmet (HTML expand) ---
let g:user_emmet_leader_key = '<C-e>'
let g:user_emmet_install_global = 0
autocmd FileType html,css,xml,xaml EmmetInstall

" --- OmniSharp (C# / XAML) ---
let g:OmniSharp_server_use_net6 = 1
let g:OmniSharp_highlight_types = 2

" --- asyncomplete ---
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>    pumvisible() ? asyncomplete#close_popup() : "\<CR>"
set completeopt+=preview
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" --- vim-lsp ---
let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_highlights_enabled = 1
let g:lsp_textprop_enabled = 1
let g:lsp_signs_enabled = 1

" --- vim-quickui Menu ---
call quickui#menu#reset()
call quickui#menu#install('&File', [
    \ ['&NERDTree Toggle   \|F3|', 'NERDTreeToggle'],
    \ ['&CtrlP Files       \|C-p|', 'CtrlP'],
    \ ['--', ''],
    \ ['&Save              \|:w|', 'w'],
    \ ['Save &All          \|:wa|', 'wa'],
    \ ['--', ''],
    \ ['&Quit              \|:q|', 'q'],
    \ ['Quit &All          \|:qa|', 'qa'],
    \ ])
call quickui#menu#install('&Edit', [
    \ ['&Comment Toggle    \|gcc|', 'Commentary'],
    \ ['&Auto Pairs        ', ''],
    \ ['--', ''],
    \ ['&Find (CtrlP)      \|C-p|', 'CtrlP'],
    \ ['&Clap Files        \|F5|', 'Clap files'],
    \ ])
call quickui#menu#install('&LSP', [
    \ ['&Go to Definition  \|gd|', 'LspDefinition'],
    \ ['&Hover Info        \|K|',  'LspHover'],
    \ ['&References        ', 'LspReferences'],
    \ ['&Rename            ', 'LspRename'],
    \ ['&Format            ', 'LspDocumentFormat'],
    \ ['--', ''],
    \ ['&Diagnostics       ', 'LspDocumentDiagnostics'],
    \ ])
call quickui#menu#install('&Git', [
    \ ['&Next Hunk         \|]c|', 'GitGutterNextHunk'],
    \ ['&Prev Hunk         \|[c|', 'GitGutterPrevHunk'],
    \ ['&Stage Hunk        ', 'GitGutterStageHunk'],
    \ ['&Undo Hunk         ', 'GitGutterUndoHunk'],
    \ ['&Preview Hunk      ', 'GitGutterPreviewHunk'],
    \ ])
call quickui#menu#install('&View', [
    \ ['&Tagbar Toggle     \|F8|', 'TagbarToggle'],
    \ ['&Indent Guides     ', 'IndentGuidesToggle'],
    \ ['&Cursorline Toggle ', 'set cursorline!'],
    \ ['--', ''],
    \ ['&Clear Highlight   \|F4|', 'nohlsearch'],
    \ ])

let g:quickui_show_tip = 1
let g:quickui_border_style = 2
" }}}

" MAPPINGS ------------------------------------------------------- {{{
let mapleader = " "

" Menu quickui
nnoremap <F1>       :call quickui#menu#open()<CR>

" NERDTree
nnoremap <F3>       :NERDTreeToggle<CR>

" Clear search highlight
nnoremap <F4>       :nohlsearch<CR>

" Clap launcher
nnoremap <F5>       :Clap files<CR>

" Tagbar
nnoremap <F8>       :TagbarToggle<CR>

" Navigation entre fenêtres
nnoremap <C-h>      <C-w>h
nnoremap <C-j>      <C-w>j
nnoremap <C-k>      <C-w>k
nnoremap <C-l>      <C-w>l

" Navigation buffers
nnoremap <Leader>n  :bnext<CR>
nnoremap <Leader>p  :bprevious<CR>
nnoremap <Leader>d  :bdelete<CR>

" LSP mappings
nnoremap <silent> gd :LspDefinition<CR>
nnoremap <silent> gr :LspReferences<CR>
nnoremap <silent> K  :LspHover<CR>
nnoremap <silent> <Leader>rn :LspRename<CR>
nnoremap <silent> <Leader>f  :LspDocumentFormat<CR>
nnoremap <silent> <Leader>e  :LspDocumentDiagnostics<CR>

" Sauvegarder rapidement
nnoremap <Leader>w  :w<CR>

" Quitter facilement
nnoremap <Leader>q  :q<CR>

" GitGutter navigation
nnoremap ]c :GitGutterNextHunk<CR>
nnoremap [c :GitGutterPrevHunk<CR>
" }}}

" VIMSCRIPT ------------------------------------------------------ {{{
" Code folding par marker
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END

" Indentation spécifique par langage
augroup lang_indent
    autocmd!
    autocmd FileType html,xml,xaml,json setlocal shiftwidth=2 tabstop=2
    autocmd FileType javascript,typescript,css setlocal shiftwidth=2 tabstop=2
    autocmd FileType python setlocal shiftwidth=4 tabstop=4
    autocmd FileType cs setlocal shiftwidth=4 tabstop=4
    autocmd FileType cpp,c setlocal shiftwidth=4 tabstop=4
augroup END

" Retour à la dernière position dans le fichier
augroup last_position
    autocmd!
    autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") |
        \   exe "normal! g`\"" |
        \ endif
augroup END
" }}}
