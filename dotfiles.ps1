# set English
Set-WinSystemLocale en-US

# eza
function DotfilesLs1
{
  eza -lh $args
}
function DotfilesLs2
{
  eza -lha $args
}
Set-Alias -name l -value DotfilesLs1
Set-Alias -name ll -value DotfilesLs2

# lazygit
Set-Alias -name lg -value lazygit

# rust/cargo
$env:PATH += ";$env:USERPROFILE\.cargo\bin"

# go
$env:GOPATH="$env:USERPROFILE\go"
$env:PATH += ";$env:GOPATH\bin"

# bob-nvim
$env:PATH += ";$env:LOCALAPPDATA\bob\nvim-bin"

# mise
mise activate pwsh | Out-String | Invoke-Expression

# starship prompt
$env:STARSHIP_CONFIG = "$env:USERPROFILE\.dotfiles\starship.toml"
Invoke-Expression (&starship init powershell)
