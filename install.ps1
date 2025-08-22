# Set-PSDebug -Trace 1

$architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$isArm = switch ($architecture)
{
  "Arm"
  { True
  }
  "Arm64"
  { True
  }
  Default
  { False
  }
}

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

function CoreDeps()
{
  Info "install core deps for windows"

  # deps
  Install -command "scoop install 7zip" -target "7z"
  Install -command "scoop install gzip" -target "gzip"
  Install -command "scoop install unzip" -target "unzip"

  scoop bucket add extras
  scoop install mingw
  scoop install coreutils
  # scoop install uutils-coreutils
  # scoop install extras/vcredist2022

  Install -command "scoop install which" -target "which"
  Install -command "scoop install gawk" -target "awk"
  Install -command "scoop install sed" -target "sed"
  Install -command "scoop install llvm" -target "clang"
  Install -command "scoop install llvm" -target "clang++"
  Install -command "scoop install make" -target "make"
  Install -command "scoop install cmake" -target "cmake"
  Install -command "scoop install gsudo" -target "gsudo"

  Install -command "scoop install gh" -target "gh"
  Install -command "scoop install curl" -target "curl"
  Install -command "scoop install wget" -target "wget"

  Install -command "scoop install extras/alacritty" -target "alacritty"

  Install -command "scoop install pipx" -target "pipx"
  pipx ensurepath
}

function JsDeps()
{
  Info "install node/deno/bun for windows"

  Install -command "scoop install deno" -target "deno"
  Install -command "scoop install bun" -target "bun"
  Install -command "scoop install fnm" -target "fnm"
  fnm env --shell powershell | Out-String | Invoke-Expression
  Install -command "fnm use --install-if-missing 22" -target "node"
}

function GitConfigs()
{
  Info "install git configs for windows"

  git config --global user.email "linrongbin16@outlook.com"
  git config --global user.name "linrongbin16"
  git config --global pull.rebase false
  git config --global init.defaultBranch main
}

function GoDeps()
{
  Info "install go deps for windows"

  Install -command "scoop install go" -target "go"
  Install -command "scoop install extras/lazygit" -target "lazygit"
  Install -command "scoop install main/fzf" -target "fzf"
}

function RustDeps()
{
  Info "install rust deps for windows"

  Install -command "scoop install rustup" -target "rustc"
  Install -command "scoop install rustup" -target "cargo"
  Install -command "scoop install fd" -target "fd"
  Install -command "scoop install ripgrep" -target "rg"
  Install -command "scoop install bat" -target "bat"
  Install -command "scoop install eza" -target "eza"
  Install -command "scoop install trashy" -target "trash"
  Install -command "cargo install --locked rmz" -target "rmz"
  Install -command "cargo install --locked cpz" -target "cpz"
}

function NeovimDeps()
{
  Info "install neovim deps for windows"

  if ($isArm)
  {
    Install "scoop install nvim" "nvim"
  } else
  {
    Install -command "cargo install --git https://github.com/MordechaiHadad/bob --locked" -target "bob"
    Install -command "bob use stable" -target "nvim"
    $env:PATH += ";$env:LOCALAPPDATA\bob\nvim-bin"
  }
}

function PromptDeps()
{
  Install -command "scoop install starship" -target "starship"
  Install -command "scoop install mise" -target "mise"
}

function AlacrittyConfigs()
{
  Info "install alacritty configs for windows"

  # alacritty.toml
  $AlacrittyFolder = "$env:APPDATA\alacritty"
  if (Test-Path -Path $AlacrittyFolder)
  {
    Remove-Item $AlacrittyFolder -Recurse -Force
  }

  gsudo { New-Item -ItemType SymbolicLink -Path "$env:APPDATA\alacritty" -Target "$env:USERPROFILE\.dotfiles\alacritty_win" }

  # alacritty/themes
  $AlacrittyThemesFolder = "$env:APPDATA\alacritty\alacritty-theme"
  if (-not (Test-Path -Path $AlacrittyThemesFolder))
  {
    git clone --depth=1 https://github.com/alacritty/alacritty-theme $AlacrittyThemesFolder
  }
}

function ProfileConfigs()
{
  Info "install PROFILE configs for windows"

  $ProfileFolder = Split-Path $PROFILE
  if (-not (Test-Path -Path $ProfileFolder))
  {
    New-Item -ItemType Directory $ProfileFolder
  }

  Write-Output '' >>$PROFILE
  Write-Output '# dotfiles' >>$PROFILE
  Write-Output '. $env:USERPROFILE\.dotfiles\dotfiles.ps1' >>$PROFILE
  Write-Output '[dotfiles] Done'
}

function Main()
{
  CoreDeps
  JsDeps
  GoDeps
  RustDeps
  NeovimDeps
  PromptDeps
  GitConfigs
  AlacrittyConfigs
  ProfileConfigs
}

Main
