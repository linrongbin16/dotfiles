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

function InstallWith([string]$command, [string]$target)
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
InstallWith -command "scoop install which" -target "which"
InstallWith -command "scoop install gawk" -target "awk"
InstallWith -command "scoop install sed" -target "sed"
InstallWith -command "scoop install llvm" -target "clang"
InstallWith -command "scoop install llvm" -target "clang++"
InstallWith -command "scoop install make" -target "make"
InstallWith -command "scoop install cmake" -target "cmake"

InstallWith -command "scoop install git" -target "git"
InstallWith -command "scoop install curl" -target "curl"
InstallWith -command "scoop install wget" -target "wget"

InstallWith -command "scoop install 7zip" -target "7z"
InstallWith -command "scoop install gzip" -target "gzip"
InstallWith -command "scoop install unzip" -target "unzip"

InstallWith -command "scoop install fd" -target "fd"
InstallWith -command "scoop install ripgrep" -target "rg"
InstallWith -command "scoop install bat" -target "bat"
InstallWith -command "scoop install eza" -target "eza"
InstallWith -command "scoop install extras/lazygit" -target "lazygit"

InstallWith -command "scoop install python" -target "python3"

InstallWith -command "scoop install vim" -target "vim"
InstallWith -command "scoop install neovim" -target "nvim"
InstallWith -command "scoop install https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/oh-my-posh.json" -target "oh-my-posh"

# python3

# $PythonHasPep668 = python3 -c 'import sys; major=sys.version_info.major; minor=sys.version_info.minor; micro=sys.version_info.micro; r1=major >= 3 and minor > 11; r2=major >= 3 and minor == 11 and micro >= 1; print(1 if r1 or r2 else 0)'
# if ($PythonHasPep668 -eq 1) {
#     python3 -m pip install click --user --break-system-packages
#     python3 -m pip install tinydb --user --break-system-packages
# } else {
python3 -m pip install click --user
python3 -m pip install tinydb --user
# }

# nerd fonts
scoop install nerd-fonts/Hack-NF
scoop install nerd-fonts/Hack-NF-Mono
scoop install nerd-fonts/Noto-NF
scoop install nerd-fonts/Noto-NF-Mono
scoop install nerd-fonts/CodeNewRoman-NF
scoop install nerd-fonts/CodeNewRoman-NF-Mono
scoop install nerd-fonts/FiraCode-NF
scoop install nerd-fonts/FiraCode-NF-Mono
scoop install nerd-fonts/SourceCodePro-NF
scoop install nerd-fonts/SourceCodePro-NF-Mono

# git config
git config --global user.email "linrongbin16@outlook.com"
git config --global user.name "linrongbin16"
git config --global pull.rebase false
git config --global core.fsmonitor true
git config --global core.untrackedcache true
git config --global init.defaultBranch main

# rust/cargo
InstallWith -command "scoop install rustup" -target "cargo"
InstallWith -command "scoop install cargo-binstall" -target "cargo-binstall"

$ProfileFolder = Split-Path $PROFILE
if (!(Test-Path -Path $ProfileFolder))
{
    New-Item -ItemType Directory $ProfileFolder
}
Write-Output '' >>$PROFILE
Write-Output '# dotfiles' >>$PROFILE
Write-Output '. $env:USERPROFILE\.dotfiles\dotfiles.ps1' >>$PROFILE

# prompt

# wezterm
if (!(Test-Path -Path $env:USERPROFILE\.wezterm.lua))
{
    cp $env:USERPROFILE\.dotfiles\.wezterm.lua $env:USERPROFILE\.wezterm.lua
}
