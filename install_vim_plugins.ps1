# ============================================================
# install_vim_plugins.ps1
# Installation automatique vim-plug + plugins + dependances
# Pour Vim sur Windows - Copier _vimrc dans C:\Users\<user>\_vimrc
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Vim Plugin Installer - Windows" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- Chemins ---
$vimDir     = "$env:USERPROFILE\vimfiles"
$autoloadDir = "$vimDir\autoload"
$plugFile   = "$autoloadDir\plug.vim"
$vimrc      = "$env:USERPROFILE\_vimrc"

# ============================================================
# 1. Verifier que Vim est installe
# ============================================================
Write-Host "[1/6] Verification de Vim..." -ForegroundColor Yellow
try {
    $vimVersion = & vim --version 2>&1 | Select-Object -First 1
    Write-Host "  OK: $vimVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERREUR: Vim non trouve dans le PATH." -ForegroundColor Red
    Write-Host "  Installe Vim depuis https://www.vim.org/download.php" -ForegroundColor Red
    Write-Host "  ou via: winget install vim.vim" -ForegroundColor Yellow
    exit 1
}

# ============================================================
# 2. Creer les dossiers vimfiles si besoin
# ============================================================
Write-Host ""
Write-Host "[2/6] Creation des dossiers vimfiles..." -ForegroundColor Yellow
foreach ($dir in @($vimDir, $autoloadDir, "$vimDir\plugged")) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Cree: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Existe deja: $dir" -ForegroundColor DarkGray
    }
}

# ============================================================
# 3. Installer vim-plug
# ============================================================
Write-Host ""
Write-Host "[3/6] Installation de vim-plug..." -ForegroundColor Yellow
if (-not (Test-Path $plugFile)) {
    try {
        $plugUrl = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
        Invoke-WebRequest -Uri $plugUrl -OutFile $plugFile -UseBasicParsing
        Write-Host "  OK: vim-plug installe dans $plugFile" -ForegroundColor Green
    } catch {
        Write-Host "  ERREUR: Impossible de telecharger vim-plug" -ForegroundColor Red
        Write-Host "  Verifie ta connexion internet" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  vim-plug deja present" -ForegroundColor DarkGray
}

# ============================================================
# 4. Copier le _vimrc
# ============================================================
Write-Host ""
Write-Host "[4/6] Copie du _vimrc..." -ForegroundColor Yellow
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceVimrc = Join-Path $scriptDir "_vimrc"

if (Test-Path $sourceVimrc) {
    if (Test-Path $vimrc) {
        $backup = "$vimrc.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $vimrc $backup
        Write-Host "  Backup cree: $backup" -ForegroundColor DarkGray
    }
    Copy-Item $sourceVimrc $vimrc -Force
    Write-Host "  OK: _vimrc copie vers $vimrc" -ForegroundColor Green
} else {
    Write-Host "  INFO: Pas de _vimrc trouve a cote du script" -ForegroundColor Yellow
    Write-Host "  Place ton _vimrc dans: $vimrc" -ForegroundColor Yellow
}

# ============================================================
# 5. Dependances externes
# ============================================================
Write-Host ""
Write-Host "[5/6] Verification des dependances externes..." -ForegroundColor Yellow

# --- curl ---
Write-Host "  curl..." -NoNewline
if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " non trouve (inclus dans Windows 10+)" -ForegroundColor Yellow
}

# --- git ---
Write-Host "  git..." -NoNewline
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " NON INSTALLE" -ForegroundColor Red
    Write-Host "    Installe git: winget install Git.Git" -ForegroundColor Yellow
}

# --- node / npm (pour vim-lsp-settings, tsserver, etc.) ---
Write-Host "  node/npm..." -NoNewline
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVer = & node --version
    Write-Host " OK ($nodeVer)" -ForegroundColor Green
} else {
    Write-Host " NON INSTALLE" -ForegroundColor Red
    Write-Host "    Installe Node.js: winget install OpenJS.NodeJS" -ForegroundColor Yellow
    Write-Host "    Requis pour: typescript-language-server, vscode-html-languageserver" -ForegroundColor Yellow
}

# --- python ---
Write-Host "  python..." -NoNewline
if (Get-Command python -ErrorAction SilentlyContinue) {
    $pyVer = & python --version
    Write-Host " OK ($pyVer)" -ForegroundColor Green
} else {
    Write-Host " NON INSTALLE" -ForegroundColor Yellow
    Write-Host "    Installe Python: winget install Python.Python.3" -ForegroundColor Yellow
}

# --- dotnet (pour OmniSharp C#) ---
Write-Host "  dotnet..." -NoNewline
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    $dotnetVer = & dotnet --version
    Write-Host " OK ($dotnetVer)" -ForegroundColor Green
} else {
    Write-Host " NON INSTALLE" -ForegroundColor Yellow
    Write-Host "    Requis pour OmniSharp (C#/XAML): winget install Microsoft.DotNet.SDK.8" -ForegroundColor Yellow
}

# --- ctags (pour tagbar) ---
Write-Host "  ctags..." -NoNewline
if (Get-Command ctags -ErrorAction SilentlyContinue) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " NON INSTALLE" -ForegroundColor Yellow
    Write-Host "    Requis pour Tagbar: winget install UniversalCtags.Ctags" -ForegroundColor Yellow
}

# ============================================================
# 6. Lancer PlugInstall dans Vim
# ============================================================
Write-Host ""
Write-Host "[6/6] Installation des plugins Vim..." -ForegroundColor Yellow
Write-Host "  Lancement de vim +PlugInstall..." -ForegroundColor DarkGray

try {
    & vim -c "PlugInstall" -c "qa!"
    Write-Host "  OK: PlugInstall termine" -ForegroundColor Green
} catch {
    Write-Host "  ERREUR lors du PlugInstall" -ForegroundColor Red
    Write-Host "  Lance manuellement: vim +PlugInstall" -ForegroundColor Yellow
}

# ============================================================
# Recapitulatif
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Installation terminee !" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Plugins installes:" -ForegroundColor White
Write-Host "  Syntaxe    : vim-polyglot, cpp-enhanced, vim-javascript, html5," -ForegroundColor DarkGray
Write-Host "               vim-css3, vim-json, vim-jsx-pretty, java-syntax, vim-xml" -ForegroundColor DarkGray
Write-Host "  LSP        : vim-lsp, asyncomplete, vim-lsp-settings, omnisharp-vim" -ForegroundColor DarkGray
Write-Host "  Web/Markup : vim-closetag, emmet-vim, MatchTagAlways" -ForegroundColor DarkGray
Write-Host "  Highlight  : rainbow, vim-illuminate, vim-indent-guides, vim-gitgutter" -ForegroundColor DarkGray
Write-Host "  Navigation : nerdtree, ctrlp, tagbar, vim-clap" -ForegroundColor DarkGray
Write-Host "  Menu       : vim-quickui (F1 pour ouvrir)" -ForegroundColor DarkGray
Write-Host "  Edition    : vim-surround, vim-commentary, auto-pairs, vim-repeat" -ForegroundColor DarkGray
Write-Host "  Interface  : vim-airline, vim-airline-themes" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Raccourcis principaux:" -ForegroundColor White
Write-Host "  F1         : Menu interactif (vim-quickui)" -ForegroundColor DarkGray
Write-Host "  F3         : NERDTree (explorateur fichiers)" -ForegroundColor DarkGray
Write-Host "  F4         : Effacer surbrillance recherche" -ForegroundColor DarkGray
Write-Host "  F5         : Clap (launcher fuzzy)" -ForegroundColor DarkGray
Write-Host "  F8         : Tagbar (fonctions/classes)" -ForegroundColor DarkGray
Write-Host "  SPACE+w    : Sauvegarder" -ForegroundColor DarkGray
Write-Host "  SPACE+q    : Quitter" -ForegroundColor DarkGray
Write-Host "  gd         : Aller a la definition (LSP)" -ForegroundColor DarkGray
Write-Host "  K          : Hover info (LSP)" -ForegroundColor DarkGray
Write-Host "  gcc        : Commenter la ligne" -ForegroundColor DarkGray
Write-Host "  C-h/j/k/l  : Navigation entre fenetres" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Pour les serveurs LSP, dans Vim:" -ForegroundColor Yellow
Write-Host "  :LspInstallServer    (installe le serveur pour le fichier ouvert)" -ForegroundColor DarkGray
Write-Host ""
