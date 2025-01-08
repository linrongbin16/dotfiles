# path
$env:PATH="$env:PATH;$env:USERPROFILE\.dotfiles\bin"

# lazygit
Set-Alias -name lg -value lazygit

# zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })
