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

# git
scoop install mingw
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

# rust
InstallOrSkip -command "scoop install rustup" -target "cargo"
InstallOrSkip -command "cargo install fd-find" -target "fd"
InstallOrSkip -command "cargo install ripgrep" -target "rg"
InstallOrSkip -command "cargo install --locked bat" -target "bat"
InstallOrSkip -command "cargo install exa" -target "exa"

# go
# see: https://github.com/kerolloz/go-installer
InstallOrSkip -command "scoop install go" -target "go"
InstallOrSkip -command "go install github.com/jesseduffield/lazygit@latest" -target "lazygit"

# prompt
git clone https://github.com/linrongbin16/mzpt.git $env:USERPROFILE\.mzpt
$ProfileFolder = Split-Path $PROFILE
if (!(Test-Path -Path $ProfileFolder)) {
    New-Item -ItemType Directory $ProfileFolder
}
Write-Output '' >>$PROFILE
Write-Output '# mzpt prompt theme' >>$PROFILE
Write-Output '. $env:USERPROFILE\.mzpt\mzpt.ps1' >>$PROFILE

# alias
Write-Output '' >>$PROFILE
Write-Output '# remove builtin alias' >>$PROFILE
Write-Output 'Get-Alias | Where-Object { $_.Options -NE "Constant" } | Remove-Alias -Force' >>$PROFILE

Write-Output '' >>$PROFILE
Write-Output '# ls' >>$PROFILE
Write-Output 'New-Alias -Name l -Value "ls -lh"' >>$PROFILE
Write-Output 'New-Alias -Name ll -Value "ls -alh"' >>$PROFILE

Write-Output '' >>$PROFILE
Write-Output '# lazygit' >>$PROFILE
Write-Output 'New-Alias -Name lg -Value "lazygit"' >>$PROFILE

Write-Output '' >>$PROFILE
Write-Output '# git' >>$PROFILE
Write-Output 'New-Alias -Name gs -Value "git status"' >>$PROFILE
Write-Output 'New-Alias -Name gp -Value "git pull"' >>$PROFILE
Write-Output 'New-Alias -Name gP -Value "git push"' >>$PROFILE
Write-Output 'New-Alias -Name ga -Value "git add"' >>$PROFILE
Write-Output 'New-Alias -Name gc -Value "git commit"' >>$PROFILE
Write-Output 'New-Alias -Name gck -Value "git checkout"' >>$PROFILE
Write-Output 'New-Alias -Name gb -Value "git branch"' >>$PROFILE
Write-Output 'New-Alias -Name gm -Value "git merge"' >>$PROFILE
