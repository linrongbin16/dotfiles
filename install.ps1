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

# Whether `$exe` is a usable `pwsh.exe`, i.e. one that runs and exits 0.
#
# `Get-Command` alone is not enough: a winget / Microsoft Store install registers an *app execution
# alias* in `%LOCALAPPDATA%\Microsoft\WindowsApps`, a reparse point that `Get-Command` reports even
# when the package behind it is gone, in which case running it opens the Store instead of a shell.
function TestPwsh([string]$exe)
{
  $previous = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try
  {
    & $exe -NoLogo -NoProfile -Command 'exit 0' 2>&1 | Out-Null
  } finally
  {
    $ErrorActionPreference = $previous
  }
  return $LASTEXITCODE -eq 0
}

# The `pwsh.exe` to run `inst/install.ps1` with, or `$null` when there is none.
#
# The well-known locations cover a fresh install: it updates the *user* PATH, which this process does
# not pick up.
function ResolvePwsh()
{
  $exe = Get-Command -Name "pwsh.exe" -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if ($exe -and (TestPwsh $exe.Source))
  {
    return $exe.Source
  }

  foreach ($candidate in @(
      (Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe"),
      (Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\pwsh.exe")
    ))
  {
    if ((Test-Path -Path $candidate) -and (TestPwsh $candidate))
    {
      return $candidate
    }
  }

  return $null
}

# Install PowerShell 7 through winget unless `pwsh.exe` already works.
#
# `--no-upgrade` keeps this an *installation*, not an upgrade: an older 7.x that already runs is left
# alone, the same "already there, leave it alone" rule the rest of the installation follows.
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
  # "the package version is already installed, installation cancelled". The second one turns up when
  # winget sees a Microsoft.PowerShell that this process cannot find on PATH -- an ARM64 machine with
  # an x64 7.x, say -- so it means "there is one, go find it", not "this failed".
  if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335135)
  {
    throw "winget failed to install 'Microsoft.PowerShell' (exit ${LASTEXITCODE})"
  }
  Info "install 'Microsoft.PowerShell' with winget - done"
}

# Run `inst/install.ps1` under `pwsh.exe` and exit with its code.
#
# `-NoProfile`: the profile of a fresh machine is not configured yet (this very script writes it),
# and one left over from an earlier installation would source `dotfiles.ps1` into the installer.
function InvokeInstaller([string]$pwsh)
{
  $installer = Join-Path $PSScriptRoot "inst\install.ps1"
  if (-not (Test-Path -LiteralPath $installer))
  {
    throw "cannot find '${installer}'"
  }

  Info "run '${installer}' with '${pwsh}'"
  & $pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $installer @scriptArgs
  exit $LASTEXITCODE
}

try
{
  # Everything below (and in `inst/install.ps1`) resolves paths relative to the checkout, so it must
  # not depend on where the caller happened to be.
  #
  # `Push-Location` rather than `Set-Location`: this script exits from `InvokeInstaller`, and a
  # `Set-Location` would take effect in the *caller's* session too. `-LiteralPath`: a checkout whose
  # path contains `[` would otherwise be read as a wildcard.
  Push-Location -LiteralPath $PSScriptRoot
  try
  {
    $pwsh = ResolvePwsh
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
  } finally
  {
    Pop-Location
  }
} catch
{
  # Report the reason, then exit non-zero so CI (and the caller) sees the failure.
  Info "install failed: $($_.Exception.Message)"
  exit 1
}
