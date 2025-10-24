#!/bin/bash

# set -x

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

install_gh() {
  (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) &&
    sudo mkdir -p -m 755 /etc/apt/keyrings &&
    out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg &&
    cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null &&
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg &&
    sudo mkdir -p -m 755 /etc/apt/sources.list.d &&
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
    sudo apt update &&
    sudo apt install gh -y
}

install_neovim() {
  if [ "$IS_ARM" == "1" ]; then
    sudo snap install nvim --classic
  fi
}

info "install deps with apt"
info "arch: $ARCH, arm: $IS_ARM"

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
install "install_gh" "gh"
install "sudo apt-get install -q -y curl" "curl"
install "sudo apt-get install -q -y wget" "wget"

install "sudo apt-get install -q -y gzip" "gzip"
install "sudo apt-get install -q -y p7zip" "7z"
install "sudo apt-get install -q -y unzip" "unzip"

install "sudo apt-get install -q -y xsel" "xsel"
install "sudo apt-get install -q -y xclip" "xclip"
install "sudo apt-get install -q -y zoxide" "zoxide"

install "sudo apt-get install -q -y python3 python3-dev python3-venv python3-pip python3-docutils" "python3"
install "sudo apt-get install -q -y python3 python3-dev python3-venv python3-pip python3-docutils" "pip3"

install "install_nodejs" "node"
install "install_nodejs" "npm"

install "sudo apt-get install pipx" "pipx"
pipx ensurepath

install "install_neovim" "nvim"

install "sudo apt-get install -q -y zsh" "zsh"
sudo chsh -s $(which zsh) $USER
