# Set-PSDebug -Trace 1

# utils {

function Info([string]$content)
{
    Write-Host "[dotfiles] - $content"
}

function SkipInfo([string]$content)
{
    Info "'$content' already exist, skip..."
}

function Install([string]$command, [string]$target)
{
    if (Get-Command -Name $target -ErrorAction SilentlyContinue)
    {
        SkipInfo $target
    } else
    {
        Info "install '${target}' with command: '${command}'"
        Invoke-Expression $command
    }
}

# utils }

Info "install dependencies for windows"

# deps
scoop bucket add extras
scoop install mingw
scoop install uutils-coreutils
Install -command "scoop install which" -target "which"
Install -command "scoop install gawk" -target "awk"
Install -command "scoop install sed" -target "sed"
Install -command "scoop install llvm" -target "clang"
Install -command "scoop install llvm" -target "clang++"
Install -command "scoop install make" -target "make"
Install -command "scoop install cmake" -target "cmake"

Install -command "scoop install git" -target "git"
Install -command "scoop install curl" -target "curl"
Install -command "scoop install wget" -target "wget"
Install -command "scoop install extras/lazygit" -target "lazygit"

Install -command "scoop install 7zip" -target "7z"
Install -command "scoop install gzip" -target "gzip"
Install -command "scoop install unzip" -target "unzip"

Install -command "scoop install vim" -target "vim"
Install -command "scoop install neovim" -target "nvim"
Install -command "scoop install starship" -target "starship"

# python3
python3 -m pip install click --user
python3 -m pip install tinydb --user
python3 -m pip install pynvim --user

# node.js
npm install --silent -g neovim
npm install --silent -g trash-cli

# nerd fonts
scoop bucket add nerd-fonts
scoop install nerd-fonts/Hack-NF
scoop install nerd-fonts/Hack-NF-Mono
scoop install nerd-fonts/D2Coding-NF
scoop install nerd-fonts/D2Coding-NF-Mono
scoop install nerd-fonts/CodeNewRoman-NF
scoop install nerd-fonts/CodeNewRoman-NF-Mono
scoop install nerd-fonts/SourceCodePro-NF
scoop install nerd-fonts/SourceCodePro-NF-Mono
scoop install nerd-fonts/Noto-NF
scoop install nerd-fonts/Noto-NF-Mono

# git config
git config --global user.email "linrongbin16@outlook.com"
git config --global user.name "linrongbin16"
git config --global pull.rebase false
git config --global init.defaultBranch main

# rust/cargo
Install -command "scoop install rustup" -target "cargo"
Install -command "cargo install fd-find" -target "fd"
Install -command "cargo install ripgrep" -target "rg"
Install -command "cargo install --locked bat" -target "bat"
Install -command "cargo install eza" -target "eza"
Install -command "cargo install --locked zoxide" -target "zoxide"

$ProfileFolder = Split-Path $PROFILE
if (!(Test-Path -Path $ProfileFolder))
{
    New-Item -ItemType Directory $ProfileFolder
}
Write-Output '' >>$PROFILE
Write-Output '# dotfiles' >>$PROFILE
Write-Output 'Invoke-Expression (& { (zoxide init powershell | Out-String) })' >>$PROFILE
Write-Output '. $env:USERPROFILE\.dotfiles\dotfiles.ps1' >>$PROFILE
