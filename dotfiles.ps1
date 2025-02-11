# path
$env:PATH="$env:PATH;$env:USERPROFILE\.dotfiles\bin"
$env:PATH="$env:PATH;$env:USERPROFILE\go\bin"
$env:PATH="$env:PATH;$env:USERPROFILE\.go\bin"

# lazygit
Set-Alias -name lg -value lazygit

# eza
function MyLs1 { eza -lh $args }
function MyLs2 { eza -lha $args }
Set-Alias -name l -value MyLs1
Set-Alias -name ll -value MyLs2

# zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# starship
$env:STARSHIP_CONFIG = "$HOME\.dotfiles\starship.toml"
Invoke-Expression (&starship init powershell)
