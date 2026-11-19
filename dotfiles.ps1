# set English
# Set-WinSystemLocale en-US

# eza
function DotLs1
{
  eza -lh $args
}
function DotLs2
{
  eza -lha $args
}
Set-Alias -name l -value DotLs1
Set-Alias -name ll -value DotLs2

# lazygit
Set-Alias -name lg -value lazygit

# git
function DotGitStatus
{
  git status $args
}
Set-Alias -name gs -value DotGitStatus
function DotGitPull
{
  git pull $args
}
# Set-Alias -name gpl -value DotGitPull
function DotGitPush
{
  git push $args
}
# Set-Alias -name gps -value DotGitPush
function DotGitAdd
{
  git add $args
}
Set-Alias -name ga -value DotGitAdd
function DotGitCommit
{
  git commit $args
}
Set-Alias -name gco -value DotGitCommit

# Add a directory to the PATH, exactly once, and in front of the other entries.
function AddPathEntry([string]$dir)
{
  if ([string]::IsNullOrEmpty($dir))
  { return 
  }
  $entries = @($env:PATH -split ';' | Where-Object { $_ })
  $target = $dir.TrimEnd('\')
  $kept = @($entries | Where-Object { $_.TrimEnd('\') -ine $target })
  $env:PATH = (@($dir) + $kept) -join ';'
}

# rust/cargo
AddPathEntry "$env:USERPROFILE\.cargo\bin"

# go
$env:GOPATH = "$env:USERPROFILE\go"
AddPathEntry (Join-Path $env:GOPATH 'bin')

# bob-nvim
AddPathEntry "$env:LOCALAPPDATA\bob\nvim-bin"

# starship prompt
#
# `starship init powershell` is what writes the prompt of the shell, so it may run only when
# starship is installed: without the guard every shell reports the missing command as a
# non-terminating error. The config of starship belongs to starship, so it goes with the init.
#
# `Get-Command` reports a missing command as an error, and `-ErrorAction SilentlyContinue` still
# writes that error into `$Error`. `-ErrorAction Ignore` writes it nowhere, so a shell without
# starship starts with an empty `$Error`.
if (Get-Command starship -ErrorAction Ignore)
{
  $env:STARSHIP_CONFIG = "$env:USERPROFILE\.dotfiles\starship.toml"
  Invoke-Expression (&starship init powershell)
}

# mise
#
# `install.ps1` installs mise on windows, so the shell activates it here: the shims of mise have
# to be in front of the PATH, otherwise the tool that wins is the one of scoop or of cargo.
#
# The activation comes after the starship prompt on purpose: starship replaces the `prompt`
# function and mise wraps the `prompt` function that it finds. The other way round, the wrapper
# of mise would be gone and `mise use` would only take effect after the next `cd`.
#
# `mise activate pwsh` writes the PATH, so it may run only once per shell: a second run puts the
# shims of mise into the PATH a second time. `__MISE_ORIG_PATH` is the marker that mise itself
# sets on the first activation, so it tells whether mise is already active.
if (-not (Test-Path -Path Env:/__MISE_ORIG_PATH) -and (Get-Command mise -ErrorAction Ignore))
{
  (&mise activate pwsh) | Out-String | Invoke-Expression
}
