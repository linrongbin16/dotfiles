# Bootstrap: make sure PowerShell 7 is installed, then hand over to `inst/install.ps1`.
#
# This script is the only one that may run under `powershell.exe` (Windows PowerShell 5.1), and it
# does one thing there: install `pwsh.exe`. Everything else runs under PowerShell 7, because
# `inst/install.ps1` starts with `#Requires -Version 7.0` and refuses to run anywhere else.

# A failing cmdlet (a bad path, a failed download, a missing command) aborts the installation
# instead of being printed and then silently ignored.
$ErrorActionPreference = 'Stop'

# The arguments this script was called with, so `InvokeInstaller` can forward them verbatim
# (`$args` is per-function inside a function body, and would only see its own extra arguments).
$scriptArgs = @($args)

function Info([string]$content)
{
  Write-Host "[dotfiles] - $content"
}

# The `pwsh.exe` on PATH, or `$null` when there is none.
#
# `Get-Command` alone is not enough: a winget / Microsoft Store install registers an *app execution
# alias* in `%LOCALAPPDATA%\Microsoft\WindowsApps`, a reparse point that `Get-Command` happily
# reports even when the package behind it is gone, in which case running it opens the Store
# instead of a shell. Requiring a non-zero exit code from `-Version` proves the binary is real.
function FindPwsh()
{
  $exe = Get-Command -Name "pwsh.exe" -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if (-not $exe)
  {
    return $null
  }

  $previous = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try
  {
    & $exe.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.Major' 2>&1 | Out-Null
  } finally
  {
    $ErrorActionPreference = $previous
  }
  if ($LASTEXITCODE -ne 0)
  {
    return $null
  }
  return $exe.Source
}

# Install PowerShell 7 through winget unless `pwsh.exe` already works.
#
# `--no-upgrade` keeps this an *installation*, not an upgrade: an older 7.x that already runs is
# left alone, the same "already there, leave it alone" rule the rest of the installation follows
# (and the reason `winget upgrade -a` is not the way to move it forward).
# `--source winget` keeps it from picking a same-named package out of the msstore source, which
# would ask for a Microsoft Store account.
function InstallPwsh()
{
  if (-not (Get-Command -Name "winget.exe" -CommandType Application -ErrorAction SilentlyContinue))
  {
    throw "winget is not on PATH, cannot install PowerShell 7 - install 'App Installer' from the Microsoft Store first"
  }

  Info "install 'Microsoft.PowerShell' with winget"
  $previous = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try
  {
    # `--disable-interactivity`: winget otherwise waits for a key press on a prompt nobody sees.
    & winget.exe install --exact --id Microsoft.PowerShell --source winget --no-upgrade `
      --accept-source-agreements --accept-package-agreements --disable-interactivity
  } finally
  {
    $ErrorActionPreference = $previous
  }

  # 0 is "installed"; -1978335135 (0x8A150061, `APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE`) is
  # "the package version is already installed, installation cancelled". The second one turns up
  # when winget sees a Microsoft.PowerShell that this process cannot find on PATH -- an ARM64
  # machine with an x64 7.x, say -- so it means "there is one, go find it", not "this failed".
  if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335135)
  {
    throw "winget failed to install 'Microsoft.PowerShell' (exit ${LASTEXITCODE})"
  }
  Info "install 'Microsoft.PowerShell' with winget - done"
}

# The `pwsh.exe` to run `inst/install.ps1` with, after `InstallPwsh` had its chance.
function ResolvePwsh()
{
  $exe = FindPwsh
  if ($exe)
  {
    return $exe
  }

  # A fresh install updates the *user* PATH, which this process does not pick up: probe the well
  # known location before giving up.
  foreach ($candidate in @(
      (Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe"),
      (Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\pwsh.exe")
    ))
  {
    if (Test-Path -Path $candidate)
    {
      return $candidate
    }
  }

  return $null
}

# Run `inst/install.ps1` under `pwsh.exe` and exit with its code.
#
# `-NoProfile`: the profile of a fresh machine is not configured yet (this very script writes it),
# and one left over from an earlier installation would source `dotfiles.ps1` into the installer.
# Extra arguments are passed through, so `.\install.ps1 -Foo` reaches the real script.
function InvokeInstaller([string]$pwsh)
{
  $installer = Join-Path $PSScriptRoot "inst\install.ps1"
  if (-not (Test-Path -Path $installer))
  {
    throw "cannot find '${installer}'"
  }

  Info "run '${installer}' with '${pwsh}'"
  & $pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $installer @scriptArgs
  exit $LASTEXITCODE
}

try
{
  $pwsh = FindPwsh
  if ($pwsh)
  {
    Info "'pwsh.exe' is already installed ('${pwsh}'), skip..."
  } else
  {
    InstallPwsh
    $pwsh = ResolvePwsh
    if (-not $pwsh)
    {
      throw "installed PowerShell 7 but 'pwsh.exe' is not usable - open a new shell and run this script again"
    }
  }

  InvokeInstaller -pwsh $pwsh
} catch
{
  # Report the reason, then exit non-zero so CI (and the caller) sees the failure.
  Info "install failed: $($_.Exception.Message)"
  exit 1
}
