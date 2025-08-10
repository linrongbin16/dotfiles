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

#### Install [Git for Windows](https://git-scm.com/download/win)

<details>
<summary>Click here to see how to install git with core utils for windows console.</summary>

Install git with the below 3 options:

- In **Select Components**, select **Associate .sh files to be run with Bash**.

  <img width="70%" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/495d894b-49e4-4c58-b74e-507920a11048" />

- In **Adjusting your PATH environment**, select **Use Git and optional Unix tools from the Command Prompt**.

  <img width="70%" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/b4f477ad-4436-4027-baa6-8320806801e2" />

- In **Configuring the terminal emulator to use with Git Bash**, select **Use Windows's default console window**.

  <img width="70%" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/f9174330-ca58-4117-a58d-9e84826c13d1" />

After this step, **git.exe** and builtin linux commands(such as **echo.exe**, **ls.exe**, **curl.exe**) will be available in `%PATH%`.

</details>

#### Install [7-Zip](https://www.7-zip.org/) (for all users)

#### Install [Python 3.x](https://www.python.org/downloads/) (only for current user)

<details>
<summary>Click here to see how to install python3 only for current user.</summary>

- Select "Customize Installation", unselect "Use admin privileges when installing py.exe".

  <img width="70%" alt="image" src="https://github.com/user-attachments/assets/e8aa9163-459e-4741-8561-c46efc2efdb5"/>

- Select all optional features without "for all users (requires admin privileges)".

  <img width="70%" alt="image" src="https://github.com/user-attachments/assets/648ec440-b0ec-4373-9c66-7bf32e48d899"/>

- Unselect "Install Python 3.12 for all users", select "Add Python to environment variables" and "Precompile standard library", choose the install directory in your user directory (for example `C:\Users\linrongbin\opt\Python312`).

  <img width="70%" alt="image" src="https://github.com/user-attachments/assets/568773e3-be4b-4b19-b444-c4880437a521"/>

- Go to the install directory (`C:\Users\linrongbin\opt\Python312`) and copy `python.exe` to `python3.exe`, and you will have `python3.exe` command in Windows PowerShell/cmd.

- Disable "python.exe" and "python3.exe" app aliases for Windows 10+. Go to Windows "Settings" => "Apps" => "App execution aliases", unselect "python.exe" and "python3.exe".

  <img width="80%" alt="image" src="https://github.com/user-attachments/assets/e6e2422d-953d-44b5-8f5e-820e2f355680"/>

  <img width="80%" alt="image" src="https://github.com/user-attachments/assets/f78d4dc2-b167-4981-9fa0-598edf8af0d5"/>

  <img width="80%" alt="image" src="https://github.com/user-attachments/assets/17baf876-e072-49eb-bed2-4b2436d85ad1"/>

</details>

#### Install [Node.js](https://nodejs.org/) (only for current user)

<details>
<summary>Click here to see how to install node only for current user.</summary>

- In "Destination Folder", choose the install directory in you user directory (for example `C:\Users\linrongbin\opt\nodejs\`).

  <img width="70%" alt="image" src="https://github.com/user-attachments/assets/abccc9b6-2b42-4679-a182-420554a6483b"/>

</details>

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
