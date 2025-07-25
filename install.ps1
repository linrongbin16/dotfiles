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
Install -command "scoop install go" -target "go"

Install -command "scoop install git" -target "git"
Install -command "scoop install curl" -target "curl"
Install -command "scoop install wget" -target "wget"
Install -command "scoop install extras/lazygit" -target "lazygit"
Install -command "scoop install main/fzf" -target "fzf"

Install -command "scoop install 7zip" -target "7z"
Install -command "scoop install gzip" -target "gzip"
Install -command "scoop install unzip" -target "unzip"

Install -command "scoop install vim" -target "vim"
Install -command "scoop install starship" -target "starship"
Install -command "scoop install mise" -target "mise"
Install -command "scoop install pipx" -target "pipx"
pipx ensurepath

# node.js
npm install --silent -g trash-cli

# git config
git config --global user.email "linrongbin16@outlook.com"
git config --global user.name "linrongbin16"
git config --global pull.rebase false
git config --global init.defaultBranch main

# rust/cargo
Install -command "scoop install rustup" -target "rustc"
Install -command "scoop install rustup" -target "cargo"
Install -command "scoop install fd" -target "fd"
Install -command "scoop install ripgrep" -target "rg"
Install -command "scoop install bat" -target "bat"
Install -command "scoop install eza" -target "eza"
Install -command "scoop install delta" -target "delta"
Install -command "scoop install zoxide" -target "zoxide"
Install -command "cargo install --git https://github.com/MordechaiHadad/bob --locked" -target "bob"
Install -command "bob use stable" -target "nvim"
$env:PATH += ";$env:LOCALAPPDATA\bob\nvim-bin"

# alacritty
$AlacrittyFolder = "$env:APPDATA\alacritty"
if (!(Test-Path -Path $AlacrittyFolder))
{
  New-Item -ItemType Directory $AlacrittyFolder
}
$AlacrittyConfig = "$env:APPDATA\alacritty\alacritty.toml"
Copy-Item ".\alacritty.toml" -Destination $AlacrittyConfig
$AlacrittyThemesFolder = "$env:APPDATA\alacritty\themes"
if (Test-Path -Path $AlacrittyThemesFolder)
{
  Remove-Item -Path $AlacrittyThemesFolder -Recurse
}
git clone --depth=1 https://github.com/alacritty/alacritty-theme $AlacrittyThemesFolder

# $PROFILE
$ProfileFolder = Split-Path $PROFILE
if (!(Test-Path -Path $ProfileFolder))
{
  New-Item -ItemType Directory $ProfileFolder
}
Write-Output '' >>$PROFILE
Write-Output '# dotfiles' >>$PROFILE
Write-Output '. $env:USERPROFILE\.dotfiles\dotfiles.ps1' >>$PROFILE
