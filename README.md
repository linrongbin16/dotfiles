# dotfiles

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/linrongbin16/dotfiles/ci.yml?label=ci)

My dot files.

## Install

### macOS/Ubuntu

A fresh machine has neither `git` nor the repository, and `git` is one of the
things this project installs (see `inst/apt.sh` and `inst/brew.sh`), so it
cannot be used to fetch it. `bootstrap` is the one file that is fetched
directly: it downloads the repository tarball with `curl` and unpacks it with
`tar`, both of which macOS and Ubuntu ship, then runs `install` from the
checkout.

```bash
curl -fsSL https://raw.githubusercontent.com/linrongbin16/dotfiles/main/bootstrap | bash
```

The repository is unpacked into `~/.dotfiles`. A branch other than `main`, or a
fork, can be picked with environment variables:

```bash
curl -fsSL https://raw.githubusercontent.com/linrongbin16/dotfiles/main/bootstrap |
  DOTFILES_REPO=my-name/dotfiles DOTFILES_BRANCH=my-branch bash
```

An existing `~/.dotfiles` checkout is used as-is, so `cd ~/.dotfiles && ./install`
still works and skips the download.

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
git clone https://github.com/linrongbin16/dotfiles.git $env:USERPROFILE\.dotfiles
cd $env:USERPROFILE\.dotfiles
.\install.ps1
```
