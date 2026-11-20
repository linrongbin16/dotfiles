#!/bin/bash

info "install deps with brew"

install_command_line_tools() {
  # `xcode-select -p` happily names a directory that does not exist yet, so ask
  # the compiler itself whether it runs. The Command Line Tools are what put
  # `clang` / `clang++` in the terminal; a full Xcode is only needed for
  # simulators and iOS work.
  if /usr/bin/xcrun --find clang >/dev/null 2>&1; then
    skip_info "xcode command line tools"
    return 0
  fi

  info "install 'xcode command line tools' with: 'softwareupdate -i'"

  # `softwareupdate` lists the tools only while this placeholder file exists.
  # Same trick as Homebrew's own installer; the download is 1-2 GB, so expect
  # this step to take a while.
  local placeholder label
  placeholder=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  sudo touch "$placeholder"
  label="$(softwareupdate -l 2>/dev/null |
    grep -B 1 -E 'Command Line Tools' |
    awk -F'*' '/^ *\*/ {print $2}' |
    sed -e 's/^ *Label: //' -e 's/^ *//' |
    sort -V |
    tail -n1)" || label=""
  sudo rm -f "$placeholder"

  if [ -z "$label" ]; then
    info "'softwareupdate -l' lists no Command Line Tools, install Xcode from the App Store"
    # `report_failure` would otherwise add a generic line after this one.
    DOTFILES_FAILURE_REPORTED=1
    return 1
  fi

  # Name the target for `report_failure`: this is a multi-minute download, and
  # a bare "a command failed" would not say what was being installed.
  DOTFILES_CURRENT_TARGET="xcode command line tools"
  sudo softwareupdate -i "$label"
  DOTFILES_CURRENT_TARGET=""

  # `softwareupdate` does not always point the developer directory at the tools
  # it just installed, and `xcrun` then still refuses to find clang.
  if ! /usr/bin/xcrun --find clang >/dev/null 2>&1; then
    DOTFILES_CURRENT_TARGET="xcode command line tools"
    sudo xcode-select --switch /Library/Developer/CommandLineTools
    DOTFILES_CURRENT_TARGET=""
  fi

  info "install 'xcode command line tools' with: 'softwareupdate -i' - done"
}

install_homebrew() {
  if [ -x /opt/homebrew/bin/brew ]; then
    skip_info "homebrew"
    return 0
  fi

  info "install 'homebrew' with: 'install.sh'"

  local script
  script="$(mktemp)"
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$script"

  # The installer asks for the password through `sudo`. With a terminal it can
  # do that; without one (CI, `./install </dev/null`) it can only run
  # unattended, which needs passwordless sudo.
  if [ -t 0 ]; then
    /bin/bash "$script"
  else
    NONINTERACTIVE=1 /bin/bash "$script"
  fi
  rm -f "$script"

  info "install 'homebrew' with: 'install.sh' - done"
}

install_command_line_tools
install_homebrew

# An existing Homebrew that this shell's PATH misses: the installer appends
# `brew shellenv` to `~/.zprofile`, which a non-login shell never reads.
if ! command -v brew >/dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew update

# c/c++ toolchain
brew install lld autoconf automake pkg-config cmake

# ssh/ssl
brew install openssl

# git
brew install git gh

# cli tools
brew install curl wget gzip p7zip unzip

# python
brew install python3

# node/deno/bun
brew install node deno oven-sh/bun/bun

# go
brew install go

# trash
brew install macos-trash

# develop tools
brew install zoxide fzf lazygit ripgrep bat fd eza tree-sitter-cli k1LoW/tap/mo mise

# neovim
install "brew install neovim" "nvim"
