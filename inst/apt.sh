#!/bin/bash

# set -x

ARCH="$(uname -m)"

IS_ARM64=0
if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  IS_ARM64=1
fi

install_nodejs() {
  # https://github.com/nodesource/distributions
  sudo apt-get install -y curl
  curl -fsSL https://deb.nodesource.com/setup_lts.x -o nodesource_setup.sh
  sudo -E bash nodesource_setup.sh
  sudo apt-get -q update
  sudo apt-get -q -y install nodejs
}

install_git() {
  sudo apt-add-repository ppa:git-core/ppa
  sudo apt-get -q -q -y update
  sudo apt-get install -q -y git
}

install_neovim() {
  if [ "$IS_ARM64" == "1" ]; then
    sudo snap install nvim --classic
  else
    install "cargo install --git https://github.com/MordechaiHadad/bob --locked" "bob"
    export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"
    bob use stable
  fi
}

info "install deps with apt"
info "arch: $ARCH, arm64: $IS_ARM64"

sudo apt-get -q -y update

install "sudo apt-get install -q -y build-essential" "gcc"
install "sudo apt-get install -q -y build-essential" "make"
install "sudo apt-get install -q -y autoconf" "autoconf"
install "sudo apt-get install -q -y automake" "automake"
install "sudo apt-get install -q -y pkg-config" "pkg-config"
install "sudo apt-get install -q -y cmake" "cmake"
sudo apt-get install -q -y libssl-dev openssl openssh-client openssh-server
sudo apt-get install -q -y cmake g++ pkg-config libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3

install "install_git" "git"
install "sudo apt-get install -q -y curl" "curl"
install "sudo apt-get install -q -y wget" "wget"

install "sudo apt-get install -q -y gzip" "gzip"
install "sudo apt-get install -q -y p7zip" "7z"
install "sudo apt-get install -q -y unzip" "unzip"

install "sudo apt-get install -q -y xsel" "xsel"
install "sudo apt-get install -q -y xclip" "xclip"

install "sudo apt-get install -q -y python3 python3-dev python3-venv python3-pip python3-docutils" "python3"
install "sudo apt-get install -q -y python3 python3-dev python3-venv python3-pip python3-docutils" "pip3"

install "install_nodejs" "node"
install "install_nodejs" "npm"

install "install_go" "go"

install "sudo apt-get install pipx" "pipx"
pipx ensurepath

install "install_neovim" "nvim"

install "sudo apt-get install -q -y zsh" "zsh"
sudo chsh -s $(which zsh) $USER
