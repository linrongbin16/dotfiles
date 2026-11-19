# Set-PSDebug -Trace 1

# Fail fast: a failing cmdlet (a bad path, a failed redirect, a missing command) aborts the
# installation instead of being printed and then silently ignored.
#
# Native commands (`scoop`, `git`, `cargo`, ...) are unaffected by this preference: their
# stderr still goes straight to the console, and their exit code is checked explicitly by
# `InvokeChecked` below.
$ErrorActionPreference = 'Stop'

$isArm = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64

# utils {

function Info([string]$content)
{
  Write-Host "[dotfiles] - $content"
}

function SkipInfo([string]$content)
{
  Info "'$content' already exist, skip..."
}

# Run `$command` and abort the whole installation when it exits with a non-zero code.
#
# This is what keeps CI honest. On Windows CI only runs `pwsh .\install.ps1` (see
# `.github/workflows/ci.yml`), so a bare `Invoke-Expression` would let a failed step pass
# unnoticed and leave the job green, unlike the bash installers there that run under
# `bash -e`. It mirrors `install()` in `inst/util.sh` for the unix side.
function InvokeChecked([string]$command, [string]$action)
{
  # Cmdlets never touch $LASTEXITCODE, so a stale value from some earlier command would be
  # mistaken for the result of this one: clear it before running.
  $global:LASTEXITCODE = 0
  Info $action
  Invoke-Expression $command
  $status = $LASTEXITCODE
  if ($status -ne 0)
  {
    throw "command failed with exit code ${status}: '${command}'"
  }
  Info "${action} - done"
}

function Install([string]$command, [string]$target)
{
  if (Get-Command -Name $target -ErrorAction SilentlyContinue)
  {
    SkipInfo $target
  } else
  {
    InvokeChecked -command $command -action "install '${target}' with command: '${command}'"
  }
}

# Install a package that provides no command to probe with `Get-Command`, e.g. `mingw` only
# appends its `bin` directory to PATH. Scoop's own install is idempotent: when the package
# is already there it warns and exits 0, so no extra guard is needed here.
function RunCommand([string]$command)
{
  InvokeChecked -command $command -action "run command: '${command}'"
}

function AddScoopBucket([string]$name)
{
  # `scoop bucket add` exits with 2 when the bucket exists (scoop's `lib/buckets.ps1:
  # add_bucket`), so probe the bucket list instead of special-casing that code.
  # scoop prints through `Write-Host`, i.e. the information stream, hence `6>&1` to read it
  # back; both Windows PowerShell 5.1 and PowerShell 7 support that.
  $global:LASTEXITCODE = 0
  $buckets = & scoop bucket list 6>&1 | Out-String
  if ($LASTEXITCODE -ne 0)
  {
    throw "failed to list scoop buckets (exit ${LASTEXITCODE})"
  }
  if ($buckets -match "(?m)^${name}\s")
  {
    SkipInfo "scoop bucket ${name}"
  } else
  {
    RunCommand -command "scoop bucket add ${name}"
  }
}

# Drop a scoop shim that shadows a build tool of the same name.
#
# `microsoft-coreutils` ships GNU `link`, which scoop exposes as `~\scoop\shims\link.exe`.
# That shim sits on PATH ahead of MSVC, so rustc resolves `link.exe` to it and every
# `cargo install` fails with `error: 2 values required for '<FILES> <FILES>' but 34 were
# provided` -- the GNU tool takes two file arguments, the MSVC linker takes a linker
# command line. `scoop shim rm` on an absent shim exits with 3, so probe the shim list
# first, the same way `AddScoopBucket` probes the bucket list.
function RemoveScoopShim([string]$name)
{
  $global:LASTEXITCODE = 0
  $shims = & scoop shim list $name 6>&1 | Out-String
  if ($LASTEXITCODE -ne 0)
  {
    throw "failed to list scoop shims (exit ${LASTEXITCODE})"
  }
  if ($shims -match "(?m)^${name}\s")
  {
    RunCommand -command "scoop shim rm ${name}"
  } else
  {
    Info "scoop shim '${name}' is not there, skip..."
  }
}

# utils }

function InstallMo()
{
  if (Get-Command -Name "mo" -ErrorAction SilentlyContinue)
  {
    SkipInfo "mo"
    return
  }

  $latestUrl = & curl.exe -fsSL -o NUL -w "%{url_effective}" "https://github.com/k1LoW/mo/releases/latest"
  if ($LASTEXITCODE -ne 0 -or -not $latestUrl)
  {
    throw "failed to resolve the latest release of mo"
  }
  $tag = "$latestUrl".Trim().Split("/")[-1]
  $asset = "mo_${tag}_windows_amd64.tar.gz"
  $url = "https://github.com/k1LoW/mo/releases/download/${tag}/${asset}"

  $localBin = Join-Path $HOME ".local\bin"
  if (-not (Test-Path -Path $localBin))
  {
    New-Item -ItemType Directory -Force -Path $localBin | Out-Null
  }

  & curl.exe -fsSL -o $asset $url
  if ($LASTEXITCODE -ne 0)
  {
    throw "failed to download ${url}"
  }
  tar -xzf $asset -C $localBin mo.exe
  if ($LASTEXITCODE -ne 0)
  {
    throw "failed to extract ${asset}"
  }

  # add ~/.local/bin to user PATH
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $pathParts = @($userPath -split ";" | Where-Object { $_ })
  if ($pathParts -notcontains $localBin)
  {
    [Environment]::SetEnvironmentVariable("Path", (@($pathParts) + $localBin) -join ";", "User")
  }
  if (($env:Path -split ";") -notcontains $localBin)
  {
    $env:Path = "$env:Path;$localBin"
  }
}

function CoreDeps()
{
  Info "install core deps for windows"

  # deps
  # `7zip` must be installed *through scoop*, not merely be present on PATH: scoop unpacks
  # `.7z` / `.tar.xz` / `.tar.lzma` downloads with its own copy of `7z.exe`
  # (`lib/decompress.ps1` -> `Get-HelperPath -Helper 7zip`, which only looks at scoop apps).
  # Probing `7z` with `Get-Command` therefore skipped this install on the CI images, which
  # ship a standalone 7-Zip that scoop cannot see, and the next `.7z` package (`mingw`)
  # failed to extract. Every package below needs it, so keep it first.
  RunCommand -command "scoop install 7zip"
  Install -command "scoop install gzip" -target "gzip"
  Install -command "scoop install unzip" -target "unzip"

  # `extras` bucket is required by `extras/vcredist2022` below.
  AddScoopBucket -name "extras"

  RunCommand -command "scoop install mingw"
  RunCommand -command "scoop install microsoft-coreutils"
  RunCommand -command "scoop install coreutils"
  # `microsoft-coreutils` puts GNU `link` on PATH as `link.exe`, which shadows the MSVC
  # linker and breaks every `cargo install` below. Must run after the coreutils installs.
  RemoveScoopShim -name "link"
  RunCommand -command "scoop install file"
  # RunCommand -command "scoop install uutils-coreutils"
  RunCommand -command "scoop install extras/vcredist2022"

  Install -command "scoop install which" -target "which"
  Install -command "scoop install gawk" -target "awk"
  Install -command "scoop install sed" -target "sed"
  if ($isArm) {
    Install -command "scoop install llvm-arm64" -target "clang"
  } else {
    Install -command "scoop install llvm" -target "clang"
  }
  Install -command "scoop install make" -target "make"
  Install -command "scoop install cmake" -target "cmake"

  Install -command "scoop install gh" -target "gh"
  Install -command "scoop install curl" -target "curl"
  Install -command "scoop install wget" -target "wget"

  InstallMo

  # Install -command "scoop install extras/alacritty" -target "alacritty"
}

function JsDeps()
{
  Info "install deno/bun for windows"

  Install -command "scoop install deno" -target "deno"
  Install -command "scoop install bun" -target "bun"
}

function GitConfigs()
{
  Info "install git configs for windows"

  RunCommand -command 'git config --global user.email "linrongbin16@outlook.com"'
  RunCommand -command 'git config --global user.name "linrongbin16"'
  RunCommand -command 'git config --global pull.rebase false'
  RunCommand -command 'git config --global init.defaultBranch main'
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
  Install -command "cargo install --locked tree-sitter-cli" -target "tree-sitter"
}

function NeovimDeps()
{
  Info "install neovim deps for windows"
  # the scoop package is named `neovim`, it installs the `nvim` binary.
  Install -command "scoop install neovim" -target "nvim"
}

function PromptDeps()
{
  Install -command "scoop install starship" -target "starship"

  # mise is disabled
  # Install -command "scoop install mise" -target "mise"
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
  ProfileConfigs
}

try
{
  Main
  Info "all done"
}
catch
{
  # Report the reason, then exit non-zero so CI (and the caller) sees the failure.
  Info "install failed: $($_.Exception.Message)"
  exit 1
}
