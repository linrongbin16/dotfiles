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
scoop install coreutils
scoop install mingw
InstallOrSkip -command "scoop install which" -target "which"
InstallOrSkip -command "scoop install llvm" -target "clang"
InstallOrSkip -command "scoop install llvm" -target "clang++"
InstallOrSkip -command "scoop install make" -target "make"
InstallOrSkip -command "scoop install cmake" -target "cmake"

InstallOrSkip -command "scoop install git" -target "git"
InstallOrSkip -command "scoop install curl" -target "curl"
InstallOrSkip -command "scoop install wget" -target "wget"

InstallOrSkip -command "scoop install 7zip" -target "7z"

InstallOrSkip -command "scoop install python" -target "python3"

InstallOrSkip -command "scoop install vim" -target "vim"
InstallOrSkip -command "scoop install neovim" -target "nvim"

# rust
InstallOrSkip -command "scoop install rustup" "cargo"
InstallOrSkip "cargo install fd-find" "fd"
InstallOrSkip "cargo install ripgrep" "rg"
InstallOrSkip "cargo install --locked bat" "bat"
InstallOrSkip "cargo install exa" "exa"

# go
# see: https://github.com/kerolloz/go-installer
install_or_skip "bash <(curl -sL https://git.io/go-installer)" "go"
install_or_skip "go install github.com/jesseduffield/lazygit@latest" "lazygit"
