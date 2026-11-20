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
if (Get-Command starship -ErrorAction Ignore)
{
  $env:STARSHIP_CONFIG = "$env:USERPROFILE\.dotfiles\starship.toml"
  Invoke-Expression (&starship init powershell)
}

# gh
#
# Use the `gh` account that matches the directory: the wrapper reads `github.user` from the
# git config of the current repository (set globally by `inst/install.ps1`, overridden per directory
# by an `includeIf` section), fetches that account's token and hands it to `gh` through
# `GH_TOKEN` for the duration of the call. Without this, `gh` always acts as the *active*
# account, which is wrong in a checkout whose `user.name` / `user.email` belong to another one.
#
# `gh` is called as `gh.exe` on purpose: inside a function named `gh`, a plain `gh` would call
# the function again. The variable is restored - or removed, when it was not set - in a
# `finally`, so one call cannot leak an identity into the next.
function gh
{
  $u = git config github.user 2>$null
  if ($u)
  {
    $tok = gh.exe auth token --user $u 2>$null
    if ($tok)
    {
      $old = $env:GH_TOKEN
      try
      {
        $env:GH_TOKEN = $tok
        gh.exe @args
      } finally
      {
        if ($null -eq $old)
        {
          Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
        } else
        {
          $env:GH_TOKEN = $old
        }
      }
      return
    }
    [Console]::Error.WriteLine("gh: no stored login for '$u' (github.user), using active account; run: gh auth login")
  }
  gh.exe @args
}

# mise
#
# `inst/install.ps1` installs mise on windows, so the shell activates it here: the shims of mise have
# to be in front of the PATH, otherwise the tool that wins is the one of scoop or of cargo.
#
# `mise activate pwsh` writes the PATH, so it may run only once per shell: a second run puts the
# shims of mise into the PATH a second time. `__MISE_ORIG_PATH` is the marker that mise itself
# sets on the first activation, so it tells whether mise is already active.
if (-not (Test-Path -Path Env:/__MISE_ORIG_PATH) -and (Get-Command mise -ErrorAction Ignore))
{
  (&mise activate pwsh) | Out-String | Invoke-Expression
}
