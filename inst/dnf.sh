#!/bin/bash

# set -x

ARCH="$(uname -m)"

IS_ARM64=0
if [[ "$architecture" == "arm64" || "$architecture" == "aarch64" ]]; then
  IS_ARM64=1
fi

install_neovim() {
  if [ "$IS_ARM64" == "1" ]; then
    sudo dnf install -y nvim
  fi
}

info "install deps with dnf"

sudo dnf check-update

install "sudo dnf group install -y \"Development Tools\"" "gcc"
install "sudo dnf group install -y \"Development Tools\"" "make"
install "sudo dnf install -y autoconf" "autoconf"
install "sudo dnf install -y automake" "automake"
install "sudo dnf install -y pkg-config" "pkg-config"
install "sudo dnf install -y cmake" "cmake"
sudo dnf install -y openssl-devel openssl openssh-clients openssh-server
sudo dnf install -y cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel g++

install "sudo dnf install -y git" "git"
install "sudo dnf install -y curl" "curl"
install "sudo dnf install -y wget" "wget"

install "sudo dnf install -y gzip" "gzip"
install "sudo dnf install -y p7zip" "7z"
install "sudo dnf install -y unzip" "unzip"

install "sudo dnf install -y xsel" "xsel"
install "sudo dnf install -y xclip" "xclip"

install "sudo dnf install -y python3 python3-devel python3-pip python3-docutils" "python3"

install "sudo dnf install -y nodejs npm" "node"

install "install_golang" "go"

install "sudo dnf install -y pipx" "pipx"
pipx ensurepath

install "install_neovim" "nvim"

install "sudo dnf install -y zsh" "zsh"
sudo chsh -s $(which zsh) $USER
