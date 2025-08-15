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

#### Install [Git for Windows](https://git-scm.com/download/win)

<details>
<summary>Click here to see how to install git with builtin shell commands for windows console.</summary>

Install git with the below 3 options:

- In **Select Components**, select **Associate .sh files to be run with Bash**.

  <img width="70%" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/495d894b-49e4-4c58-b74e-507920a11048" />

- In **Adjusting your PATH environment**, select **Use Git and optional Unix tools from the Command Prompt**.

  <img width="70%" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/b4f477ad-4436-4027-baa6-8320806801e2" />

- In **Configuring the terminal emulator to use with Git Bash**, select **Use Windows's default console window**.

  <img width="70%" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/f9174330-ca58-4117-a58d-9e84826c13d1" />

After this step, **git.exe** and builtin shell commands(such as **echo.exe**, **ls.exe**, **curl.exe**) will be available in `%PATH%`.

</details>

#### Install [7-Zip](https://www.7-zip.org/)

#### Run PowerShell Command

```powershell
# scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

cd $env:USERPROFILE
git clone https://github.com/linrongbin16/dotfiles.git .dotfiles
cd .dotfiles
.\install.ps1
```
