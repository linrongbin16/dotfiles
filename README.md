# dotfiles

My dotfiles.

## Install

### MacOS/Linux

> MacOS please install [xcode](https://developer.apple.com/support/xcode/) and [homebrew](https://brew.sh/) as pre-requirements.
>
> ```bash
> # xcode
> xcode-select --install
> # homebrew
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
> ```

Zsh/Bash:

```bash
cd ~
git clone git@github.com:linrongbin16/dotfiles.git .dotfiles
cd .dotfiles
./install
```

### Windows

> Please choose x86_64 for all below dependencies.

#### Developer Mode

Enable [developer mode](https://learn.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development#activate-developer-mode) for Windows.

#### Visual Studio

Install [Visual Studio](https://www.visualstudio.com/) with the below 2 components:

- .NET Desktop Development
- Desktop development with C++

![image](https://github.com/linrongbin16/lin.nvim/assets/6496887/bca811b5-8b1a-42c0-9283-c38e75f2f06a)

#### Run PowerShell Command

```powershell
# scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

cd $env:USERPROFILE
git clone git@github.com:linrongbin16/dotfiles.git .dotfiles
cd .dotfiles
.\install.ps1
```
