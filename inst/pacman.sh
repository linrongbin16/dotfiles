#!/bin/bash

# set -x

ARCH="$(uname -m)"

IS_ARM64=0
if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  IS_ARM64=1
fi

install_neovim() {
  if [ "$IS_ARM64" == "1" ]; then
    yes | sudo pacman -S nvim
  fi
}

info "install deps with pacman"
info "arch: $ARCH, arm64: $IS_ARM64"

sudo pacman -Syy

install "yes | sudo pacman -S base-devel" "gcc"
install "yes | sudo pacman -S base-devel" "make"
install "yes | sudo pacman -S autoconf" "autoconf"
install "yes | sudo pacman -S automake" "automake"
install "yes | sudo pacman -S pkg-config" "pkg-config"
install "yes | sudo pacman -S cmake" "cmake"
yes | sudo pacman -S libssl openssl openssh
yes | sudo pacman -S cmake freetype2 fontconfig pkg-config make libxcb libxkbcommon python

install "yes | sudo pacman -S git" "git"
install "yes | sudo pacman -S curl" "curl"
install "yes | sudo pacman -S wget" "wget"

install "yes | sudo pacman -S unzip" "unzip"
install "yes | sudo pacman -S gzip" "gzip"
install "yes | sudo pacman -S p7zip" "7z"
install "yes | sudo pacman -S atool" "atool"

install "yes | sudo pacman -S xsel" "xsel"
install "yes | sudo pacman -S xclip" "xclip"

install "yes | sudo pacman -S python python-pip" "python3"

install "yes | sudo pacman -S nodejs npm" "node"

install "yes | sudo pacman -S go" "go"

install "yes | sudo pacman -S python-pipx" "pipx"
pipx ensurepath

install "yes | sudo pacman -S zsh" "zsh"
sudo chsh -s $(which zsh) $USER
