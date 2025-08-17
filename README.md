# dotfiles

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/linrongbin16/dotfiles/ci.yml?label=ci)

My dot files.

## Install

### MacOS/Linux

> MacOS please install [xcode](https://developer.apple.com/support/xcode/) and [homebrew](https://brew.sh/) as pre-requirements.

Zsh/Bash:

```bash
cd ~
git clone https://github.com/linrongbin16/dotfiles.git .dotfiles
cd .dotfiles
./install
```

### Windows

> Please choose x86_64 for all below dependencies.

#### Enable developer mode

Please see: [active developer mode](https://learn.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development#activate-developer-mode).

#### Install [Visual Studio](https://www.visualstudio.com/)

Install with below components:

- .NET Desktop Development
- Desktop development with C++

![image](https://github.com/linrongbin16/lin.nvim/assets/6496887/bca811b5-8b1a-42c0-9283-c38e75f2f06a)

#### Install [PowerShell](https://github.com/PowerShell/PowerShell)

```powershell
winget install Microsoft.PowerShell
```

#### Install [Git for Windows](https://git-scm.com/downloads/win)

> [!CAUTION]
> The "Git for Windows" is mandatory, other third party git versions (such as `scoop install git`) may not work with `gh` authorization.

> [!NOTE]
> This command installs `git` in `~\.local\bin\git` directory, with specific setup options via `/LOADINF`. It enables unix command lines such as `bash`, `sh`, `echo` in Cmd/PowerShell, making windows terminal behave more like a unix shell.

```powershell
winget install --no-upgrade --disable-interactivity --scope user -l $env:USERPROFILE\.local\bin\git --custom /LOADINF=$env:USERPROFILE\.dotfiles\git_for_windows.ini --id Git.Git -e --source winget
```

#### Install [7-Zip](https://www.7-zip.org/)

#### Run PowerShell Command

> [!CAUTION]
> Run below commands with builtin "PowerShell 7" terminal, not any other third party terminals.
> Since they may panic with 'gsudo' administrator privilege.

```powershell
# pwsh
winget install Microsoft.PowerShell

# git
winget install --id Git.Git -e --source winget

# Remove 'python3' App Alias from Windows
Remove-Item $env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe
Remove-Item $env:LOCALAPPDATA\Microsoft\WindowsApps\python3.exe

# scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Run 'install.ps1'
cd $env:USERPROFILE
git clone https://github.com/linrongbin16/dotfiles.git .dotfiles
cd .dotfiles
.\install.ps1
```
