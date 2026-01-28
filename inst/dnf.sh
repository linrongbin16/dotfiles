#!/bin/bash

# set -x

install_gh() {
  sudo dnf install -y dnf5-plugins
  sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
  sudo dnf install -y gh --repo gh-cli
}

install_lazygit() {
  sudo dnf copr enable dejan/lazygit
  sudo dnf install -y lazygit
}

info "install deps with dnf"
info "arch: $ARCH, arm: $IS_ARM"

sudo dnf check-update

sudo dnf group install -y "Development Tools"
sudo dnf install -y llvm llvm-devel clang clang-tools-extra libcxx-devel lld mold
install "sudo dnf install -y autoconf" "autoconf"
install "sudo dnf install -y automake" "automake"
install "sudo dnf install -y pkg-config" "pkg-config"
install "sudo dnf install -y cmake" "cmake"
sudo dnf install -y openssl-devel openssl openssh-clients openssh-server perl-core
sudo dnf install -y cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel g++

install "sudo dnf install -y git" "git"
install "install_gh" "gh"
install "sudo dnf install -y curl" "curl"
install "sudo dnf install -y wget" "wget"

install "sudo dnf install -y gzip" "gzip"
install "sudo dnf install -y p7zip" "7z"
install "sudo dnf install -y unzip" "unzip"

install "sudo dnf install -y xsel" "xsel"
install "sudo dnf install -y xclip" "xclip"
install "sudo dnf install -y zoxide" "zoxide"

install "sudo dnf install -y python3 python3-devel python3-pip python3-docutils" "python3"

install "sudo dnf install -y nodejs npm" "node"

install "sudo dnf install -y golang" "go"
install "sudo dnf install -y fzf" "fzf"
install "install_lazygit" "lazygit"
install "sudo dnf install -y ripgrep" "rg"
install "sudo dnf install -y bat" "bat"
install "sudo dnf install -y fd-find" "fd"

install "sudo dnf install -y pipx" "pipx"
pipx ensurepath

install "sudo dnf install -y neovim" "nvim"

install "sudo dnf install -y zsh" "zsh"
sudo chsh -s $(which zsh) $USER
