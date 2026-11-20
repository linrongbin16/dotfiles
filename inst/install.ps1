#Requires -Version 7.0
# The installation itself, and PowerShell 7 only: `install.ps1` in the repository root is the entry
# point, it installs `pwsh.exe` when it is missing and re-launches this file with it. The `#Requires`
# above is what keeps a `powershell.exe` (5.1) call from getting this far.

# Set-PSDebug -Trace 1

# Fail fast: a failing cmdlet (a bad path, a failed redirect, a missing command) aborts the
# installation instead of being printed and then silently ignored.
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

# Whether `$command` is on PATH *and* actually runs, e.g. `cargo --version` exiting 0.
function TestCommand([string]$command, [string]$Arguments = "--version")
{
  # `-First 1`: PATH can hold two copies of the same binary (say a scoop shim and the one in
  # `~/.cargo\bin`), and `Get-Command` then answers with an array that `&` refuses to run.
  $exe = Get-Command -Name $command -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if (-not $exe)
  {
    return $false
  }
  $previous = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try
  {
    & $exe $Arguments 2>&1 | Out-Null
  } finally
  {
    $ErrorActionPreference = $previous
  }
  return $LASTEXITCODE -eq 0
}

# The scoop app names installed on this machine, e.g. `ripgrep`. Cached: the installer probes
# two dozen packages and one `scoop list` costs ~0.3s.
function GetScoopApps()
{
  if ($null -eq $script:ScoopApps)
  {
    # `scoop list` prints its header through `Write-Host`
    $script:ScoopApps = @(& scoop list 6>$null | ForEach-Object { $_.Name } | Where-Object { $_ })
  }
  return $script:ScoopApps
}

# Install a scoop package and pin it with `scoop hold`, so `scoop update` leaves it alone.
function InstallScoopHeld([string]$app)
{
  # No `-target` argument on purpose: owning the version is what is being asked for, so a
  # `python` left on PATH by some other installer must not turn the install into a no-op.
  InstallScoop $app

  $name = $app.Split('/')[-1]
  InvokeChecked -command "scoop hold ${name}" -action "hold '${name}', so 'scoop update' skips it"
}

# Install a scoop package unless scoop already has it.
function InstallScoop([string]$app, [string]$target)
{
  $name = $app.Split('/')[-1]
  if ((GetScoopApps) -contains $name)
  {
    SkipInfo $name
    return
  }

  # The one question `scoop list` cannot answer: a command from somewhere else says nothing
  # about what scoop installed, but it does mean scoop's copy would only shadow it.
  if (-not [string]::IsNullOrEmpty($target) -and (Get-Command -Name $target -ErrorAction SilentlyContinue))
  {
    SkipInfo $target
    return
  }

  InvokeChecked -command "scoop install ${app}" -action "install '${name}' with command: 'scoop install ${app}'"
}

# The crates installed into this `CARGO_HOME`, e.g. `rmz`.
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

# Install a crate unless it is already in this `CARGO_HOME`. `tree-sitter-cli` is the reason this
# cannot be `Get-Command`: the crate ships `tree-sitter.exe`, not `tree-sitter-cli.exe`.
function InstallCargo([string]$crate)
{
  if ((GetCargoCrates) -contains $crate)
  {
    SkipInfo $crate
  } else
  {
    $command = "cargo binstall --locked --no-confirm --disable-telemetry ${crate}"
    InvokeChecked -command $command -action "install '${crate}' with command: '${command}'"
  }
}

# Install a package that provides no command to probe with `Get-Command`, e.g. `mingw` only
# appends its `bin` directory to PATH. Scoop's own install is idempotent: when the package
# is already there it warns and exits 0, so no extra guard is needed here.
function RunCommand([string]$command)
{
  InvokeChecked -command $command -action "run command: '${command}'"
}

# Add `$dir` to the PATH of the current process, when it is not there yet.
function AddProcessPathEntry([string]$dir)
{
  if (($env:Path -split ";") -notcontains $dir)
  {
    $env:Path = "$env:Path;$dir"
  }
}

# Add `$dir` to the persisted PATH of the current user, when it is not there yet.
function AddUserPathEntry([string]$dir)
{
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $pathParts = @($userPath -split ";" | Where-Object { $_ })
  if ($pathParts -notcontains $dir)
  {
    [Environment]::SetEnvironmentVariable("Path", (@($pathParts) + $dir) -join ";", "User")
  }
}

function AddScoopBucket([string]$name)
{
  # `scoop bucket add` exits with 2 when the bucket exists (scoop's `lib/buckets.ps1:
  # add_bucket`), so probe the bucket list instead of special-casing that code.
  # scoop prints through `Write-Host`, i.e. the information stream, hence `6>&1` to read it back.
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

# Install `mo`, the GitHub issue formatter, from its upstream release archive.
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

  # Download and unpack in a private temporary directory. The archive used to be saved into the
  # current working directory, which left a `mo_<tag>_windows_amd64.tar.gz` behind in the
  # repository root -- hidden only by the `mo*.tar.gz` rule in `.gitignore`.
  $tempBase = $env:TEMP
  if (-not $tempBase)
  { $tempBase = $env:TMP 
  }
  if (-not $tempBase)
  { $tempBase = [System.IO.Path]::GetTempPath() 
  }
  $tempRoot = [System.IO.Path]::GetFullPath($tempBase)
  $workDir = [System.IO.Path]::GetFullPath((Join-Path $tempRoot ("mo-install-" + [guid]::NewGuid().ToString("N"))))

  try
  {
    New-Item -ItemType Directory -Force -Path $workDir | Out-Null
    $archive = Join-Path $workDir "mo.tar.gz"

    # Upstream publishes a Windows build for x86-64 only (`mo_<tag>_windows_amd64.tar.gz`), so an
    # ARM64 Windows has to run that build under emulation. Ask for a native build first and fall
    # back to x86-64, so a future upstream release is picked up without another change here.
    $architectures = @('amd64')
    if ($isArm)
    {
      $architectures = @('arm64', 'amd64')
    }

    $url = ''
    $architecture = ''
    $failure = ''
    foreach ($arch in $architectures)
    {
      $asset = "mo_${tag}_windows_${arch}.tar.gz"
      $candidateUrl = "https://github.com/k1LoW/mo/releases/download/${tag}/${asset}"
      try
      {
        & curl.exe -fsSL -o $archive $candidateUrl
        if ($LASTEXITCODE -eq 0)
        {
          $url = $candidateUrl
          $architecture = $arch
          break
        }
        $failure = "curl exited with ${LASTEXITCODE}"
      } catch
      {
        # A host that turns a native exit code into a terminating error must not abort the
        # whole installation: the next architecture may still be available.
        $failure = $_.Exception.Message
      }
      if ($arch -eq $architectures[-1])
      {
        break
      }
      Info "no ${arch} build of mo ${tag} (${failure}), trying the next architecture"
    }
    if (-not $url)
    {
      throw "failed to download mo ${tag} for windows ($($architectures -join ', ')): ${failure}"
    }
    if ($isArm -and $architecture -eq 'amd64')
    {
      Info "upstream publishes no Windows/arm64 build of mo, using the x86-64 build (windows runs it under emulation)"
    }

    # Unpack into the temporary directory first, and copy only the binary into `~/.local\bin`:
    # the archive also holds the license and the readme.
    $extractDir = Join-Path $workDir "extract"
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    tar -xzf $archive -C $extractDir mo.exe
    if ($LASTEXITCODE -ne 0)
    {
      throw "failed to extract ${url}"
    }
    $exe = Join-Path $extractDir "mo.exe"
    if (-not (Test-Path -Path $exe))
    {
      throw "the archive ${url} does not contain mo.exe"
    }

    $localBin = Join-Path $HOME ".local\bin"
    New-Item -ItemType Directory -Force -Path $localBin | Out-Null
    Copy-Item -Path $exe -Destination (Join-Path $localBin "mo.exe") -Force
    Info "installed mo ${tag} into ${localBin}"
  } finally
  {
    # Remove only the directory this function created, and only when it really is a child of
    # the temporary directory. A leftover must not fail an otherwise finished installation.
    if ((Split-Path -Path $workDir -Parent) -eq $tempRoot)
    {
      Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
    }
  }

  # add ~/.local/bin to user PATH
  AddUserPathEntry -dir $localBin
  AddProcessPathEntry -dir $localBin
}

# Turn off the `python.exe` / `python3.exe` *app execution aliases* in
# `%LOCALAPPDATA%\Microsoft\WindowsApps`.
function DisableWindowsAppsPythonAlias()
{
  $windowsApps = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps"
  foreach ($alias in @("python.exe", "python3.exe"))
  {
    $path = Join-Path $windowsApps $alias
    # `Get-Item` rather than `Test-Path`: the entry is a reparse point, so `Test-Path` answers
    # `$false` for one whose target is gone -- exactly the state the Store leaves behind, and
    # not something to report as "already disabled" without removing anything.
    $entry = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if (-not $entry)
    {
      Info "the '${alias}' app execution alias is already disabled, skip..."
      continue
    }
    Remove-Item -LiteralPath $path -Force
    Info "disabled the '${alias}' app execution alias in ${windowsApps}"
  }
}

# Install the latest stable Python 3 through scoop, then pin it.
#
# The `python` bucket entry wraps python.org's own `.exe` build: its installer script expands
# the dark archive inside and unrolls the MSIs, so nothing interactive ever runs here -- the
# GUI that makes `winget install` unusable on this machine never gets a chance to appear.
#
# Scoop also owns what a hand-rolled ZIP install has to rebuild: `python3.exe` comes from the
# `bin` list, the `pip` console scripts from `post_install` calling `ensurepip`, and `Scripts`
# onto PATH from `env_add_path`. All of that is the bucket maintainer's problem now.
function InstallPython3()
{
  InstallScoopHeld "python"

  # `Add-Path` prepends, so the scoop directories sit ahead of the `%LOCALAPPDATA%` aliases --
  # but on a machine where the Store aliases are still armed, `python3` there is a redirector
  # to the Microsoft Store, and an ordering accident should not decide which one wins.
  DisableWindowsAppsPythonAlias
}

# Install the latest Node.js LTS through scoop, then pin it.
#
# Same reasoning as `InstallPython3`: the bucket ships the official nodejs.org archive (a plain
# directory inside a `.7z`), `env_add_path` puts it on PATH, and `post_install` rewrites `npmrc`
# so the global prefix and the cache land in the persisted directory instead of `%APPDATA%`.
# Node.js keeps a single active LTS line, so `nodejs-lts` *is* "latest LTS" -- the bucket's
# `checkver` reads `dist/index.json` the same way the old getter did.
function InstallNodejs()
{
  InstallScoopHeld "nodejs-lts"
}

# Turn on Windows *developer mode*, so this machine can sideload and debug apps without the
# interactive trip through the Settings app that README.md used to ask for.
#
# `AllowDevelopmentWithoutDevLicense` is the value behind the "Developer Mode" toggle (Microsoft's
# documented alternative to the Settings page). The Settings page also installs the Developer Mode
# package of optional features, which only remote deployment needs; for local development the value
# is what decides, and it is set in HKLM, i.e. an elevated process is required -- the account of a
# developer is an administrator, and the CI runner has the same rights.
function EnableDeveloperMode()
{
  $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
  $name = 'AllowDevelopmentWithoutDevLicense'

  if ((Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue).$name -eq 1)
  {
    SkipInfo "developer mode"
    return
  }

  # Report the reason instead of dying in `New-Item` with a bare "Access to the registry key ...
  # is denied": the fix is known, and it is not something this script can do on its own.
  $principal = [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent())
  if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
  {
    throw "enabling developer mode writes '${key}\${name}' and needs an elevated PowerShell - run this script as administrator"
  }

  Info "enable developer mode"
  New-Item -Path $key -Force | Out-Null
  New-ItemProperty -Path $key -Name $name -PropertyType DWord -Value 1 -Force | Out-Null
  Info "enable developer mode - done"
}

function Deps()
{
  Info "install core deps for windows"

  # First: several packages below (and the toolchains that trust their binaries) assume a machine
  # that is allowed to run code that did not come from the Store.
  EnableDeveloperMode

  # `7zip` must be installed *through scoop* and must stay first,
  # all following scoop installations need it.
  RunCommand -command "scoop install 7zip"

  # `extras` bucket
  AddScoopBucket -name "extras"

  # shell environment
  RunCommand -command "scoop install mingw"
  RunCommand -command "scoop install coreutils"
  RunCommand -command "scoop install extras/vcredist2022"
  RunCommand -command "scoop install https://raw.githubusercontent.com/unixwin/niubash/master/installer/scoop/niubash.json"

  # c/c++ toolchain
  if ($isArm)
  {
    InstallScoop "llvm-arm64"
  } else
  {
    InstallScoop "llvm"
  }
  InstallScoop "make"
  InstallScoop "cmake"

  # gh
  InstallScoop "gh"

  # cli tools
  InstallScoop "gzip"
  InstallScoop "unzip"
  InstallScoop "curl"
  InstallScoop "wget"
  InstallScoop "which"
  InstallScoop "gawk"
  InstallScoop "sed"

  # python3
  InstallPython3

  # node/deno/bun
  InstallNodejs
  InstallScoop "deno"
  InstallScoop "bun"

  # go
  InstallScoop "go"

  # develop tools
  InstallScoop "extras/lazygit"
  InstallScoop "main/fzf"
  InstallScoop "fd"
  InstallScoop "ripgrep"
  InstallScoop "bat"
  InstallScoop "eza"
  InstallScoop "trashy"
  InstallMo
  InstallScoop "mise"
  InstallScoop "starship"
}

# Point the git credential helper at `gh`, so `git pull` / `git push` over HTTPS authenticate
# with the token `gh` already stored (the keyring) instead of asking for a password.
#
# This is what `gh auth setup-git` writes, spelled out here because that command stores the
# absolute path of the `gh.exe` it ran from -- `C:\users\<user>\scoop\apps\gh\current\...` is a
# symlink that moves on every scoop upgrade, and a stale copy of the path in `.gitconfig` makes
# every HTTPS fetch fail with "could not read Password". The bare `gh` below is resolved through
# PATH on each call instead.
function SetGitHubCredentialHelper()
{
  # Fail here, with the reason, rather than writing a helper that no `git` invocation can run.
  if (-not (Get-Command -Name gh -ErrorAction SilentlyContinue))
  {
    throw "gh is not on PATH, cannot configure the git credential helper"
  }

  foreach ($ghHost in @('github.com', 'gist.github.com'))
  {
    $key = "credential.https://${ghHost}.helper"

    # A *leading empty* `helper` value, then the `gh` command: `git` accumulates helpers from
    # `system`, `global` and repo scope, and an empty value clears the list built so far. Git for
    # Windows ships `manager` at system scope, so without the reset `manager` would run first and
    # prompt for a password -- the exact failure this is here to prevent.
    #
    # `--replace-all` rather than `--add`: a re-run then rewrites the pair instead of stacking a
    # second copy of the same shell command, which makes `git` call the keyring twice.
    #
    # The `""` is a real empty argument: PowerShell 7 on Windows quotes native arguments itself
    # (`$PSNativeCommandArgumentPassing = 'Windows'`, the default since 7.4), so `git` receives an
    # empty value. 5.1 dropped the argument instead, and `git` died with
    # `wrong number of arguments, should be from 2 to 3`.
    RunCommand -command ('git config --global --replace-all "{0}" ""' -f $key)

    RunCommand -command "git config --global --add ${key} '!gh auth git-credential'"
  }
}

function GitConfigs()
{
  Info "install git configs for windows"

  # [user]
  RunCommand -command 'git config --global user.email "linrongbin16@outlook.com"'
  RunCommand -command 'git config --global user.name "linrongbin16"'
  # [github]
  RunCommand -command 'git config --global github.user "linrongbin16"'

  RunCommand -command 'git config --global pull.rebase false'
  RunCommand -command 'git config --global init.defaultBranch main'

  # [safe] *
  RunCommand -command 'git config --global --replace-all safe.directory "*"'

  SetGitHubCredentialHelper
}

# Install `rustup` and its default (stable) toolchain from the Rust project instead of scoop.
function InstallRustup()
{
  # The installer edits the *user* PATH, which this process does not pick up, so `cargo` would
  # still be "not recognized" for the `cargo install` calls below on a fresh machine. Done
  # first: the probes should look at the directory the install puts its proxies in.
  $cargoBin = Join-Path $HOME ".cargo\bin"
  if (($env:PATH -split ';') -notcontains $cargoBin)
  {
    $env:PATH = "${cargoBin};$env:PATH"
  }

  if (TestCommand "rustup")
  {
    SkipInfo "rustup"
    if ((TestCommand "rustc") -and (TestCommand "cargo"))
    {
      return
    }
    InvokeChecked -command "rustup default stable" -action "install the default rust toolchain"
    return
  }

  $triple = "x86_64-pc-windows-msvc"
  if ($isArm)
  {
    $triple = "aarch64-pc-windows-msvc"
  }
  $url = "https://static.rust-lang.org/rustup/dist/${triple}/rustup-init.exe"
  $installer = Join-Path $env:TEMP "rustup-init.exe"

  Info "download '${url}'"
  & curl.exe -fsSL -o $installer $url
  if ($LASTEXITCODE -ne 0)
  {
    throw "failed to download ${url}"
  }

  InvokeChecked -command "& '${installer}' -y --default-toolchain stable" -action "install rustup with the stable toolchain"
  # Cleanup only: a leftover installer in TEMP must not fail an otherwise finished install.
  Remove-Item -Path $installer -Force -ErrorAction SilentlyContinue

  # Fail here, with the reason, rather than in the first `cargo install` with a bare
  # "not recognized as the name of a cmdlet".
  if (-not (TestCommand "cargo"))
  {
    throw "rustup finished but 'cargo' is not usable (expected '${cargoBin}')"
  }
}

# Install `cargo-binstall`, the `cargo install` replacement `InstallCargo` uses.
function InstallCargoBinstall()
{
  if (TestCommand "cargo-binstall" "-V")
  {
    SkipInfo "cargo-binstall"
    return
  }

  $url = "https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.ps1"
  Info "download '${url}'"
  $installer = (Invoke-WebRequest -Uri $url).Content

  # `iex` runs the body in *this* function's scope, so the variables it assigns (`$tmpdir`, `$zip`,
  # `$cargo_bin`, ...) stay here instead of leaking into the rest of the script. `4>$null` drops the
  # timing lines it writes with `Write-Verbose -Verbose`, which are not this script's log format.
  Invoke-Expression $installer 4>$null

  # Fail here, with the reason, rather than in the first `cargo binstall` with a bare
  # "no such command: `binstall`".
  if (-not (TestCommand "cargo-binstall" "-V"))
  {
    $cargoBin = Join-Path $HOME ".cargo\bin"
    throw "ran the cargo-binstall installer but 'cargo-binstall' is not usable (expected '${cargoBin}')"
  }
}

# Install the latest stable neovim through `bob`, instead of a scoop package that pins one build.
#
# `bob` keeps every version it installs in its own directory and switches by rewriting that
# directory's `nvim-bin`; `dotfiles.ps1` already puts `%LOCALAPPDATA%\bob\nvim-bin` on PATH, so
# `nvim` here is whatever `bob use` selected last.
function InstallNeovim()
{
  # Fail here, with the reason, rather than in `bob use` with a bare
  # "not recognized as the name of a cmdlet".
  if (-not (TestCommand "bob"))
  {
    $cargoBin = Join-Path $HOME ".cargo\bin"
    throw "installed 'bob-nvim' but 'bob' is not usable (expected '${cargoBin}')"
  }

  # `bob use` is idempotent (an already-installed version is a no-op), and "stable" is resolved
  # upstream, so a probe here would only go stale: let bob decide what stable is today.
  RunCommand -command "bob use stable"
}

function RustDeps()
{
  Info "install rust deps for windows"

  InstallRustup
  InstallCargoBinstall
  InstallCargo "rmz"
  InstallCargo "cpz"
  InstallCargo "tree-sitter-cli"
  InstallCargo "bob-nvim"
  InstallNeovim
}

# Detect the encoding an existing startup file is stored in, by its byte order mark.
#
# This script writes BOM-less UTF-8, but the file it appends to is not necessarily its own: a
# `~/.niubashrc` (or a profile) created from an older Windows PowerShell is still UTF-16LE, its
# `>>` wrote that. Appending UTF-8 bytes to a UTF-16LE file corrupts it: the appended line is
# read back as CJK gibberish and every shell start fails with `The term '...' is not recognized
# as the name of a cmdlet`.
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
    } finally
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

# Append the `# dotfiles` marker and one source line to a shell startup file, unless the
# source line is already in there.
#
# `-newLine` defaults to CRLF, which is what the PowerShell profiles take; a bash rc gets
# LF instead, so writing into `~/.niubashrc` does not mix line endings in one file.
#
# `-probe` is an optional regex that also counts as "already there", for an rc that was
# hand-configured before this script had a line for it: `~/.niubashrc` may already carry a
# bare `. ~/.dotfiles/dotfiles.sh`, which is not this exact line but would source the file
# a second time -- and `dotfiles.sh` prepends PATH entries, so they would stack.
function AddProfileSource([string]$path, [string]$line, [string]$newLine = "`r`n", [string]$probe = '')
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
    $trimmed = $existing.Trim()
    if ($trimmed -eq $line)
    {
      Info "source '${line}' is already in '${path}', skip..."
      return
    }
    if ($probe -and $trimmed -match $probe)
    {
      Info "'${path}' already sources dotfiles ('${trimmed}'), skip..."
      return
    }
  }

  # Append through `[System.IO.File]::AppendAllText` with an explicit encoder, rather than
  # `Add-Content`, because the target file's encoding has to be preserved: `Add-Content -Encoding
  # utf8` writes a BOM when it has to create the file.
  #
  # `AppendAllText` does not terminate the previous line, so close it first when the file
  # does not end with a newline; keep the blank separator line the old version wrote.
  $prefix = ''
  if ($content.Length -gt 0)
  {
    if (-not $content.EndsWith("`n"))
    {
      $prefix += $newLine
    }
    $prefix += $newLine
  }

  # Write back in the encoding the file already uses, so an old UTF-16LE profile stays
  # readable instead of turning into half UTF-8.
  $block = "${prefix}# dotfiles${newLine}${line}${newLine}"
  [System.IO.File]::AppendAllText($path, $block, $encoding)
}

function ProfileConfigs()
{
  Info "install PROFILE configs for windows"

  $line = '. $env:USERPROFILE\.dotfiles\dotfiles.ps1'

  # Only the PowerShell 7 profile: this script runs under pwsh 7 (`install.ps1` in the repository
  # root starts it there and never under `powershell.exe` 5.1), so `$PROFILE` names exactly the
  # file that `pwsh` reads on startup -- including on a machine whose Documents folder was
  # relocated (OneDrive), where `$HOME\Documents` is not the answer.
  AddProfileSource -path $PROFILE -line $line

  # `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` (README.md) covers 5.1 only: it writes
  # `HKCU:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell`, which pwsh 7 does not
  # read. 7 has its own policies under `...\PowerShell\7\...` and is pinned to `RemoteSigned` by
  # `$PSHOME\powershell.config.json`, so there is nothing to set up here.

  # Add source `dotfiles.sh` for `~/.niubashrc`.
  $niubashrc = Join-Path $env:USERPROFILE ".niubashrc"
  AddProfileSource `
    -path $niubashrc `
    -line '[ -f ~/.dotfiles/dotfiles.sh ] && source ~/.dotfiles/dotfiles.sh' `
    -newLine "`n" `
    -probe '^(?:\.|source)\s+\S*dotfiles\.sh$'
}

function Main()
{
  Deps
  RustDeps
  GitConfigs
  ProfileConfigs
  Info "done"
}

try
{
  Main
} catch
{
  # Report the reason, then exit non-zero so CI (and the caller) sees the failure.
  Info "install failed: $($_.Exception.Message)"
  exit 1
}
