# Set-PSDebug -Trace 1

$isArm64 = $Env:PROCESSOR_ARCHITECTURE -eq "ARM64"

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
  scoop bucket add extras
  scoop install mingw
  # scoop install uutils-coreutils
  scoop install coreutils
  # scoop install vcredist2022
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

  Install -command "scoop install 7zip" -target "7z"
  Install -command "scoop install gzip" -target "gzip"
  Install -command "scoop install unzip" -target "unzip"

  Install -command "scoop install extras/alacritty" -target "alacritty"

  Install -command "scoop install pipx" -target "pipx"
  pipx ensurepath
}

function PythonDeps()
{
  Info "install python deps for windows"
  $PythonVersion = "3.13.6"
  $PythonArch = "amd64"

  if ($isArm64)
  {
    $PythonArch = "arm64"
  }

  $PythonDownloadUrl = "https://www.python.org/ftp/python/{0}/python-{0}-{1}.exe" -f $PythonVersion, $PythonArch
  Info "PythonDownloadUrl: $PythonDownloadUrl"

  Invoke-WebRequest -UseBasicParsing -Uri ("https://www.python.org/ftp/python/{0}/python-{0}-{1}.exe" -f $PythonVersion, $PythonArch) -OutFile "python-installer.exe"
  Get-ChildItem

  $LocalFolder = "$env:USERPROFILE\.local\bin"
  if (-not (Test-Path -Path $LocalFolder))
  {
    New-Item -ItemType Directory $LocalFolder
  }

  .\python-installer.exe /quiet InstallAllUsers=0 DefaultJustForMeTargetDir="$LocalFolder\python3" PrependPath=1 InstallLauncherAllUsers=0 Include_launcher=0 | Wait-Process

  Info "LocalFolder: $LocalFolder"
  Get-ChildItem -Path "$LocalFolder"

  # Python Windows installer doesn't provide the 'python3.exe' executable, thus here we create a copy for it.
  Copy-Item "$LocalFolder\python3\python.exe" -Destination "$LocalFolder\python3\python3.exe"
}

function JsDeps()
{
  Info "install node/deno/bun for windows"

  Install -command "scoop install deno" -target "deno"
  Install -command "scoop install bun" -target "bun"
  Install -command "scoop install fnm" -target "fnm"
  fnm env --shell powershell | Out-String | Invoke-Expression
  Install -command "fnm use --install-if-missing 22" -target "node"
 
  npm install --silent -g trash-cli
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
  Install -command "cargo install --locked rmz" -target "rmz"
  Install -command "cargo install --locked cpz" -target "cpz"
}

function NeovimDeps()
{
  Info "install neovim deps for windows"

  if ($isArm64)
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

  # alacritty_win.toml
  $AlacrittyFolder = "$env:APPDATA\alacritty"
  if (-not (Test-Path -Path $AlacrittyFolder))
  {
    New-Item -ItemType Directory $AlacrittyFolder
  }
  $AlacrittyConfig = "$env:APPDATA\alacritty\alacritty_win.toml"
  Copy-Item ".\alacritty_win.toml" -Destination $AlacrittyConfig

  # alacritty/themes
  $AlacrittyThemesFolder = "$env:APPDATA\alacritty\themes"
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
  PythonDeps
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
