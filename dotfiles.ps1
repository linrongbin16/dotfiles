# set English
Set-WinSystemLocale en-US

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
Set-Alias -name gpl -value DotGitPull
function DotGitPush
{
  git push $args
}
Set-Alias -name gps -value DotGitPush
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
