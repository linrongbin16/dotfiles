# Set-PSDebug -Trace 1

# utils

function Message([string]$content)
{
    Write-Host "[dotfiles] - $content"
}

function SkipMessage([string]$content) {
	Message "'$content' already exist, skip..."
}

function InstallOrSkip([string]$command, [string]$target)
{
    if (Get-Command -Name $target -ErrorAction SilentlyContinue)
    {
        SkipMessage $target
    }
    else
    {
        Message "install '${target}' with command: '${command}'"
        Invoke-Expression $command
    }
}

Message "install dependencies for windows"

# deps
scoop install mingw
scoop install uutils-coreutils
InstallOrSkip -command "scoop install which" -target "which"
InstallOrSkip -command "scoop install gawk" -target "awk"
InstallOrSkip -command "scoop install sed" -target "sed"
InstallOrSkip -command "scoop install llvm" -target "clang"
InstallOrSkip -command "scoop install llvm" -target "clang++"
InstallOrSkip -command "scoop install make" -target "make"
InstallOrSkip -command "scoop install cmake" -target "cmake"

InstallOrSkip -command "scoop install git" -target "git"
InstallOrSkip -command "scoop install curl" -target "curl"
InstallOrSkip -command "scoop install wget" -target "wget"

InstallOrSkip -command "scoop install 7zip" -target "7z"
InstallOrSkip -command "scoop install gzip" -target "gzip"
InstallOrSkip -command "scoop install unzip" -target "unzip"
InstallOrSkip -command "scoop install unrar" -target "unrar"

InstallOrSkip -command "scoop install python" -target "python3"

InstallOrSkip -command "scoop install vim" -target "vim"
InstallOrSkip -command "scoop install neovim" -target "nvim"

# git config
git config --global user.email "linrongbin16@outlook.com"
git config --global user.name "linrongbin16"
git config --global pull.rebase false
git config --global core.fsmonitor true
git config --global core.untrackedcache true
git config --global init.defaultBranch main

# rust
InstallOrSkip -command "scoop install rustup" -target "cargo"
InstallOrSkip -command "cargo install fd-find" -target "fd"
InstallOrSkip -command "cargo install ripgrep" -target "rg"
InstallOrSkip -command "cargo install --locked bat" -target "bat"

# go
# see: https://github.com/kerolloz/go-installer
InstallOrSkip -command "scoop install go" -target "go"
InstallOrSkip -command "go install github.com/jesseduffield/lazygit@latest" -target "lazygit"

# prompt
if (!(Test-Path -Path $env:USERPROFILE\.mzpt)) {
    git clone https://github.com/linrongbin16/mzpt.git $env:USERPROFILE\.mzpt
}
$ProfileFolder = Split-Path $PROFILE
if (!(Test-Path -Path $ProfileFolder)) {
    New-Item -ItemType Directory $ProfileFolder
}
Write-Output '' >>$PROFILE
Write-Output '# ======== .dotfiles start ========' >>$PROFILE
Write-Output '' >>$PROFILE
Write-Output '# mzpt prompt theme' >>$PROFILE
Write-Output '. $env:USERPROFILE\.mzpt\mzpt.ps1' >>$PROFILE
Write-Output '' >>$PROFILE
Write-Output '# path' >>$PROFILE
Write-Output '$env:PATH="$env:PATH;$env:USERPROFILE\.dotfiles\bin"' >>$PROFILE
Write-Output '# ======== .dotfiles end ========' >>$PROFILE
Write-Output '' >>$PROFILE
