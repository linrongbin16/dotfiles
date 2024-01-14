# path
$env:PATH="$env:PATH;$env:USERPROFILE\.dotfiles\bin"

# oh-my-posh theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/pure.omp.json" | Invoke-Expression

# alias
Set-Alias -name gnvim -value neovide
Set-Alias -name lg -value lazygit
