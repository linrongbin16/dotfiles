#!/bin/bash

# set -x

. "$DOTFILES_HOME/inst/util.sh"

IS_LINUX=1

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

install_lazygit() {
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit -D -t /usr/local/bin/
}

apt_depends() {
  info "install dependencies with apt"
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
  install "install_deno" "deno"
  install "install_bun" "bun"

  install "install_go" "go"
  install "install_lazygit" "lazygit"

  install "sudo apt-get install pipx" "pipx"
  pipx ensurepath
  sudo pipx ensurepath --global

  install "sudo apt-get install -q -y zsh" "zsh"
  sudo chsh -s $(which zsh) $USER
}
