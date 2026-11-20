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

  # Niubash (`niu`): a bash-compatible shell for Windows, no WSL and no MSYS. Its README installs
  # from the in-repo scoop manifest, because the Extras-bucket submission
  # (ScoopInstaller/Extras#19334) has not merged yet -- switch this to `InstallScoop "niubash"`
  # once `scoop search niubash` finds it. `InstallScoop` cannot guard the URL form: it derives
  # the name from the last URL segment, i.e. `niubash.json`, which never matches the installed
  # app `niubash` in `scoop list`. Going through it would re-run the install on every run, so
  # the plain `RunCommand` relies on scoop's own idempotence (it warns "'niubash' (1.5.0) is
  # already installed" and exits 0).
  RunCommand -command "scoop install https://raw.githubusercontent.com/unixwin/niubash/master/installer/scoop/niubash.json"

  # InstallScoop "extras/alacritty"
}

function JsDeps()
{
  Info "install deno/bun for windows"

  InstallScoop "deno"
  InstallScoop "bun"
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
    RunCommand -command "git config --global --replace-all ${key} ''"
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

function GoDeps()
{
  Info "install go deps for windows"

  InstallScoop "go"
  InstallScoop "extras/lazygit"
  InstallScoop "main/fzf"
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
  # `-UseBasicParsing` because PowerShell 5.1 otherwise parses the body with the Internet Explorer
  # engine, which fails on a machine where IE has never been started. (PowerShell 7 ignores it.)
  $installer = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content

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

function RustDeps()
{
  Info "install rust deps for windows"

  InstallRustup
  InstallCargoBinstall
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
  InstallScoop "neovim" "nvim"
}

function PromptDeps()
{
  InstallScoop "starship"
  InstallScoop "mise"
}

# Open the execution policy of `powershell.exe` 5.1, so the profile written below can load.
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

  # Niubash reads exactly one startup file on Windows, `~/.niubashrc`, in plain bash syntax
  # (`~/.bashrc` is never sourced there), so the bash half of the dotfiles gets its own line.
  # Same guard as `profile_configs` in the `install` script: the line only sources
  # `dotfiles.sh` when the checkout is there, instead of erroring on a machine without it.
  #
  # Force LF: `niu setup` writes this file with LF, and `AppendAllText` would otherwise inject
  # CRLF into a bash script. niu tolerates CRLF, but a mixed-ending rc trips `git diff` and any
  # editor that normalizes on save.
  #
  # `-probe` covers an rc that was already wired by hand with a bare `. ~/.dotfiles/dotfiles.sh`:
  # appending the guarded line next to it would source `dotfiles.sh` twice and stack the PATH
  # entries it prepends.
  $niubashrc = Join-Path $env:USERPROFILE ".niubashrc"
  AddProfileSource `
    -path $niubashrc `
    -line '[ -f ~/.dotfiles/dotfiles.sh ] && source ~/.dotfiles/dotfiles.sh' `
    -newLine "`n" `
    -probe '^(?:\.|source)\s+\S*dotfiles\.sh$'
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
  Info "done"
} catch
{
  # Report the reason, then exit non-zero so CI (and the caller) sees the failure.
  Info "install failed: $($_.Exception.Message)"
  exit 1
}
