#!/bin/bash

# set -x

info "install deps with pacman"
info "arch: $ARCH, arm: $IS_ARM"

sudo pacman -Syy

yes | sudo pacman -S base-devel
yes | sudo pacman -S llvm clang lld mold
install "yes | sudo pacman -S autoconf" "autoconf"
install "yes | sudo pacman -S automake" "automake"
install "yes | sudo pacman -S pkg-config" "pkg-config"
install "yes | sudo pacman -S cmake" "cmake"
yes | sudo pacman -S libssl openssl openssh
yes | sudo pacman -S cmake freetype2 fontconfig pkg-config make libxcb libxkbcommon python

install "yes | sudo pacman -S git" "git"
install "yes | sudo pacman -S github-cli" "gh"
install "yes | sudo pacman -S curl" "curl"
install "yes | sudo pacman -S wget" "wget"

install "yes | sudo pacman -S unzip" "unzip"
install "yes | sudo pacman -S gzip" "gzip"
install "yes | sudo pacman -S p7zip" "7z"
install "yes | sudo pacman -S atool" "atool"

install "yes | sudo pacman -S xsel" "xsel"
install "yes | sudo pacman -S xclip" "xclip"
install "yes | sudo pacman -S zoxide" "zoxide"

install "yes | sudo pacman -S python python-pip" "python3"

install "yes | sudo pacman -S nodejs npm" "node"

install "yes | sudo pacman -S go" "go"
install "yes | sudo pacman -S fzf" "fzf"
install "yes | sudo pacman -S lazygit" "lazygit"
install "yes | sudo pacman -S ripgrep" "rg"
install "yes | sudo pacman -S bat" "bat"
install "yes | sudo pacman -S fd" "fd"
install "yes | sudo pacman -S eza" "eza"

install "yes | sudo pacman -S python-pipx" "pipx"
pipx ensurepath

install "yes | sudo pacman -S neovim" "nvim"

install "yes | sudo pacman -S zsh" "zsh"
sudo chsh -s $(which zsh) $USER
