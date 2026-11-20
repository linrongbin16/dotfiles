# dotfiles

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/linrongbin16/dotfiles/ci.yml?label=ci)

My dot files.

## Install

### macOS/Ubuntu

```bash
# Git for Ubuntu
sudo apt-add-repository -y ppa:git-core/ppa \
         && sudo apt-get -q -q -y update \
         && sudo apt-get install -q -y git

# Git for macOS
brew install git

git clone https://github.com/linrongbin16/dotfiles.git ~/.dotfiles \
        && cd ~/.dotfiles \
        && ./install
```

### Windows

#### Install [Visual Studio](https://www.visualstudio.com/)

Install with below components:

- .NET Desktop Development
- Desktop development with C++

![image](https://github.com/linrongbin16/lin.nvim/assets/6496887/bca811b5-8b1a-42c0-9283-c38e75f2f06a)

#### Run PowerShell Command

```powershell
# scoop for Windows
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Git for Windows
scoop install git

git clone https://github.com/linrongbin16/dotfiles.git $env:USERPROFILE\.dotfiles
cd $env:USERPROFILE\.dotfiles
.\install.ps1
```
