# go
$env:GOROOT="$env:USERPROFILE\.go"
$env:GOPATH="$env:USERPROFILE\go"
$env:PATH += ";$env:GOROOT\bin"
$env:PATH += ";$env:GOPATH\bin"

# neovim
$env:PATH += ";$env:LOCALAPPDATA\bob\nvim-bin"

# lazygit
Set-Alias -name lg -value lazygit

# eza
function MyLs1 { eza -lh $args }
function MyLs2 { eza -lha $args }
Set-Alias -name l -value MyLs1
Set-Alias -name ll -value MyLs2

# starship
$env:STARSHIP_CONFIG = "$HOME\.dotfiles\starship.toml"
Invoke-Expression (&starship init powershell)
