# Set-PSDebug -Trace 1

# Fail fast: a failing cmdlet (a bad path, a failed redirect, a missing command) aborts the
# installation instead of being printed and then silently ignored.
#
# Native commands (`scoop`, `git`, `cargo`, ...) are unaffected by this preference as long as
# their streams are not redirected: their stderr goes straight to the console, and their exit
# code is checked explicitly by `InvokeChecked` below. Redirecting it (`2>$null`) would change
# that under PowerShell 5.1, where each redirected line becomes an error record -- see
# `GetCargoCrates`.
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

# Install a package when *any* provider of `$target` will do, i.e. when the requirement is
# "this command must exist", not "this package must be installed by this manager".
#
# Only for the two cases where a foreign installation is the intended setup -- bob owns
# `nvim`, a rustup.rs toolchain owns `rustc`/`cargo` -- because scoop installing its own copy
# next to them puts a second `nvim.exe`/`rustc.exe` on PATH. Everything else probes the
# package with `InstallScoop` / `InstallCargo` below.
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

# The scoop app names installed on this machine, e.g. `ripgrep`. Cached: the installer probes
# two dozen packages and one `scoop list` costs ~0.3s.
#
# `Get-Command` cannot answer "is this scoop package installed". Under PowerShell 5.1 it
# resolves `curl` and `wget` to the `Invoke-WebRequest` alias, and unrelated tools earlier
# on PATH answer for packages scoop never installed (`niubash`'s `winuxcmd` provides
# `which`/`awk`/`sed`/`fd`/`rg`). Probing the package name is the only way to see what
# scoop itself sees.
function GetScoopApps()
{
  if ($null -eq $script:ScoopApps)
  {
    # `scoop list` prints its header through `Write-Host`, i.e. the information stream, and
    # the rows as objects with a `Name` property. The exit code only reports "nothing is
    # installed at all" (1) -- a filter that matches nothing still exits 0 -- so the names
    # are the only usable signal. Empty means "assume nothing is installed" and install.
    $script:ScoopApps = @(& scoop list 6>$null | ForEach-Object { $_.Name } | Where-Object { $_ })
  }
  return $script:ScoopApps
}

# Install a scoop package unless scoop already has it.
#
# `$app` is the name scoop knows, not the binary the package ships: `gawk` provides `awk`,
# `neovim` provides `nvim`, `trashy` provides `trash`. A bucket prefix is allowed
# (`extras/lazygit`) because `scoop install` accepts it, but `scoop list` reports the bare
# name, hence the split.
function InstallScoop([string]$app)
{
  $name = $app.Split('/')[-1]
  if ((GetScoopApps) -contains $name)
  {
    SkipInfo $name
  } else
  {
    InvokeChecked -command "scoop install ${app}" -action "install '${name}' with command: 'scoop install ${app}'"
  }
}

# The crates `cargo install` has put on this machine, e.g. `rmz`. `cargo install --list`
# prints `<name> v<version>:` followed by the binaries it installed, so the version line is
# the crate name. Cached for the same reason as `GetScoopApps`.
#
# The exit code is ignored on purpose: a broken or absent `--list` yields no names, i.e.
# "nothing is installed", and the `cargo install` that follows fails loudly with the real
# error instead of the installer quietly skipping a dependency.
#
# Its stderr is left alone rather than redirected to `$null`: under PowerShell 5.1 every
# redirected stderr line from a native command becomes an error record, and the
# `$ErrorActionPreference = 'Stop'` above turns the first one into a terminating error. `cargo`
# writes its diagnostics there (any warning, any failing `--list`), so discarding them would make
# the probe throw instead of returning "nothing installed" and letting the real `cargo install`
# report the error.
function GetCargoCrates()
{
  if ($null -eq $script:CargoCrates)
  {
    if (Get-Command -Name cargo -ErrorAction SilentlyContinue)
    {
      $script:CargoCrates = @(
        & cargo install --list | ForEach-Object {
          if ($_ -match '^(\S+) v\d')
          {
            $Matches[1]
          }
        }
      )
    } else
    {
      # No toolchain yet: let the `cargo install` below fail loudly instead of guessing.
      $script:CargoCrates = @()
    }
  }
  return $script:CargoCrates
}

# Install a crate unless `cargo install` already put it here. `tree-sitter-cli` is the reason
# this cannot be `Get-Command`: the crate ships `tree-sitter.exe`, not `tree-sitter-cli.exe`.
function InstallCargo([string]$crate)
{
  if ((GetCargoCrates) -contains $crate)
  {
    SkipInfo $crate
  } else
  {
    InvokeChecked -command "cargo install --locked ${crate}" -action "install '${crate}' with command: 'cargo install --locked ${crate}'"
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
  InstallScoop "gzip"
  InstallScoop "unzip"

  # `extras` bucket is required by `extras/vcredist2022` below.
  AddScoopBucket -name "extras"

  RunCommand -command "scoop install mingw"
  RunCommand -command "scoop install coreutils"
  RunCommand -command "scoop install file"
  RunCommand -command "scoop install extras/vcredist2022"

  InstallScoop "which"
  InstallScoop "gawk"
  InstallScoop "sed"
  if ($isArm)
  {
    InstallScoop "llvm-arm64"
  } else
  {
    InstallScoop "llvm"
  }
  InstallScoop "make"
  InstallScoop "cmake"

  InstallScoop "gh"
  InstallScoop "curl"
  InstallScoop "wget"

  InstallMo

  # InstallScoop "extras/alacritty"
}

function JsDeps()
{
  Info "install deno/bun for windows"

  InstallScoop "deno"
  InstallScoop "bun"
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

  InstallScoop "go"
  InstallScoop "extras/lazygit"
  InstallScoop "main/fzf"
}

function RustDeps()
{
  Info "install rust deps for windows"

  # A rustup.rs toolchain already provides `rustc`/`cargo` outside scoop, and scoop's `rustup`
  # would add a second pair to PATH, so a working toolchain is reason enough to skip.
  Install -command "scoop install rustup" -target "rustc"
  InstallScoop "fd"
  InstallScoop "ripgrep"
  InstallScoop "bat"
  InstallScoop "eza"
  InstallScoop "trashy"
  InstallCargo "rmz"
  InstallCargo "cpz"
  InstallCargo "tree-sitter-cli"
}

function NeovimDeps()
{
  Info "install neovim deps for windows"
  # bob manages `nvim` in this setup; scoop's `neovim` would shadow it on PATH, so an `nvim`
  # from anywhere is enough. The scoop package is named `neovim`, it ships the `nvim` binary.
  Install -command "scoop install neovim" -target "nvim"
}

function PromptDeps()
{
  InstallScoop "starship"

  # mise is disabled
  # InstallScoop "mise"
}

# Open the execution policy of `powershell.exe` 5.1, so the profile written below can load.
#
# `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` (README.md) is not enough: run under
# pwsh 7 it writes `Documents\PowerShell\powershell.config.json`, a file `powershell.exe`
# never reads. 5.1 reads `HKCU:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell`
# and, left at the Windows default `Restricted`, refuses to source any profile -- every launch
# then prints `running scripts is disabled on this system` and `dotfiles.ps1` never runs.
#
# The value is written straight to the registry instead of shelling out to
# `powershell.exe -Command Set-ExecutionPolicy`: no child process, and the result is the same
# no matter which host ran the installer. Policies that already allow local scripts are kept.
function SetExecutionPolicyForWindowsPowerShell()
{
  $key = 'HKCU:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'

  $current = $null
  if (Test-Path -Path $key)
  {
    $current = (Get-ItemProperty -Path $key).ExecutionPolicy
  }

  # `AllSigned` is deliberately not in this list: it would still refuse the unsigned profile.
  if (@('RemoteSigned', 'Unrestricted', 'Bypass') -contains $current)
  {
    Info "windows powershell execution policy is '${current}', skip..."
    return
  }

  New-Item -Path $key -Force | Out-Null
  Set-ItemProperty -Path $key -Name 'ExecutionPolicy' -Value 'RemoteSigned'
  Info "set windows powershell execution policy 'RemoteSigned' (was '${current}') - done"
}

# Detect the encoding a profile file is already stored in, by its byte order mark.
#
# Windows PowerShell 5.1's `>>` wrote UTF-16LE, so a profile created by an older installer is
# still UTF-16LE while everything this script writes is BOM-less UTF-8. Appending UTF-8 bytes
# to a UTF-16LE file corrupts it: the appended line is read back as CJK gibberish and every
# shell start fails with `The term '...' is not recognized as the name of a cmdlet`.
function GetProfileEncoding([string]$path)
{
  $head = New-Object byte[] 3
  $read = 0
  if (Test-Path -Path $path)
  {
    $stream = [System.IO.File]::OpenRead($path)
    try
    {
      $read = $stream.Read($head, 0, $head.Length)
    }
    finally
    {
      $stream.Dispose()
    }
  }

  if ($read -ge 2 -and $head[0] -eq 0xFF -and $head[1] -eq 0xFE)
  {
    return [System.Text.UnicodeEncoding]::new($false, $true) # UTF-16LE
  }
  if ($read -ge 3 -and $head[0] -eq 0xEF -and $head[1] -eq 0xBB -and $head[2] -eq 0xBF)
  {
    return [System.Text.UTF8Encoding]::new($true) # UTF-8 with BOM
  }

  # Missing file or no BOM: BOM-less UTF-8, which is what this script writes.
  return [System.Text.UTF8Encoding]::new($false)
}

# Append the `# dotfiles` marker and the `dotfiles.ps1` source line to one profile file,
# unless the source line is already in there.
function AddProfileSource([string]$path, [string]$line)
{
  New-Item -ItemType Directory -Path (Split-Path $path) -Force | Out-Null

  $encoding = GetProfileEncoding -path $path

  $content = ''
  if (Test-Path -Path $path)
  {
    $content = [System.IO.File]::ReadAllText($path, $encoding)
  }

  # Probe before appending: the block used to be written unconditionally, so every re-run
  # added another copy and `dotfiles.ps1` got sourced once more per run, stacking the PATH
  # entries it appends.
  foreach ($existing in $content -split "\r?\n")
  {
    if ($existing.Trim() -eq $line)
    {
      Info "source '${line}' is already in '${path}', skip..."
      return
    }
  }

  # Append through `[System.IO.File]::AppendAllText` with an explicit encoder.
  # `>>` is not usable here: under Windows PowerShell 5.1 it appends UTF-16LE, which
  # corrupts a UTF-8 profile and makes it fail to parse. `Add-Content -Encoding utf8` is
  # closer but still writes a BOM when it has to create the file.
  #
  # `AppendAllText` does not terminate the previous line, so close it first when the file
  # does not end with a newline; keep the blank separator line the old version wrote.
  $prefix = ''
  if ($content.Length -gt 0)
  {
    if (-not $content.EndsWith("`n"))
    {
      $prefix += "`r`n"
    }
    $prefix += "`r`n"
  }

  # Write back in the encoding the file already uses, so an old UTF-16LE profile stays
  # readable instead of turning into half UTF-8.
  $block = "${prefix}# dotfiles`r`n${line}`r`n"
  [System.IO.File]::AppendAllText($path, $block, $encoding)

  Info "done"
}

function ProfileConfigs()
{
  Info "install PROFILE configs for windows"

  $line = '. $env:USERPROFILE\.dotfiles\dotfiles.ps1'

  # `$PROFILE` only names the running host's own profile, so writing that one left the other
  # host unconfigured: `.\install.ps1` under `powershell.exe` 5.1 wrote
  # `Documents\WindowsPowerShell\...`, and pwsh 7 then loaded nothing. Configure both, using
  # `MyDocuments` rather than `$HOME\Documents` so a relocated (OneDrive) Documents folder
  # still resolves to where PowerShell actually looks.
  #
  # The 5.1 side also needs its execution policy opened: `Set-ExecutionPolicy RemoteSigned
  # -Scope CurrentUser` in README.md writes `HKCU:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\
  # Microsoft.PowerShell`, which `powershell.exe` reads and pwsh 7 ignores (7 is pinned to
  # RemoteSigned by `$PSHOME\powershell.config.json`). Skipping it leaves 5.1 at `Restricted`,
  # where sourcing the profile fails and every launch prints a `running scripts is disabled`
  # error -- the very failure this dual-profile support is meant to avoid.
  SetExecutionPolicyForWindowsPowerShell

  $documents = [Environment]::GetFolderPath('MyDocuments')
  $profiles = @(
    (Join-Path $documents "PowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path $documents "WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
  )
  foreach ($path in $profiles)
  {
    AddProfileSource -path $path -line $line
  }
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
} catch
{
  # Report the reason, then exit non-zero so CI (and the caller) sees the failure.
  Info "install failed: $($_.Exception.Message)"
  exit 1
}
