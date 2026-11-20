# dotfiles

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/linrongbin16/dotfiles/ci.yml?label=ci)

My dot files.

## Install

### macOS/Ubuntu

```bash
git clone https://github.com/linrongbin16/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install
```

### Windows

#### Enable developer mode

Please see: [active developer mode](https://learn.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development#activate-developer-mode).

#### Install [Visual Studio](https://www.visualstudio.com/)

Install with below components:

- .NET Desktop Development
- Desktop development with C++

![image](https://github.com/linrongbin16/lin.nvim/assets/6496887/bca811b5-8b1a-42c0-9283-c38e75f2f06a)

#### Install Third-Party Pre-Requirements

```powershell
# pwsh
winget install --no-upgrade --disable-interactivity Microsoft.PowerShell

# 7zip
winget install --no-upgrade --disable-interactivity -e --id 7zip.7zip

# scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# git
scoop install git
```

#### Run PowerShell Command

```powershell
cd $env:USERPROFILE
git clone https://github.com/linrongbin16/dotfiles.git .dotfiles
cd .dotfiles
.\install.ps1
```
