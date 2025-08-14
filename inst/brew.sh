#!/bin/bash

# set -x

install_zsh() {
  brew install zsh
  sudo chsh -s /opt/homebrew/bin/zsh $USER
}

info "install deps with brew"

install "xcode-select --install" "clang"
install "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)\"" "brew"
brew update

install "brew install autoconf" "autoconf"
install "brew install automake" "automake"
install "brew install pkg-config" "pkg-config"
install "brew install cmake" "cmake"
brew install openssl openssh

install "brew install git" "git"
install "brew install curl" "curl"
install "brew install wget" "wget"

install "brew install gzip" "gzip"
install "brew install p7zip" "7z"
install "brew install unzip" "unzip"
install "brew install alacritty" "alacritty"

install "brew install python3" "python3"

install "brew install node" "node"
install "brew install deno" "deno"
install "brew install oven-sh/bun/bun" "bun"

install "brew install go" "go"
install "brew install jesseduffield/lazygit/lazygit" "lazygit"
install "brew install fzf" "fzf"
install "brew install trash" "/opt/homebrew/opt/trash/bin/trash"

install "brew install pipx" "pipx"
pipx ensurepath

# install arm-64 zsh for mac
install "install_zsh" "/opt/homebrew/bin/zsh"
