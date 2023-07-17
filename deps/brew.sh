#!/bin/bash

DEPS=$1
source $DEPS/util.sh

message "install dependencies with brew"
brew update

install_or_skip "brew install autoconf" "autoconf"
install_or_skip "brew install automake" "automake"
install_or_skip "brew install pkg-config" "pkg-config"
install_or_skip "brew install cmake" "cmake"

install_or_skip "brew install git" "git"
install_or_skip "brew install curl" "curl"
install_or_skip "brew install wget" "wget"

install_or_skip "brew install unzip" "unzip"
install_or_skip "brew install gzip" "gzip"
install_or_skip "brew install p7zip" "7z"
install_or_skip "brew install atool" "atool"

install_or_skip "brew install python3" "python3"

install_or_skip "brew install vim" "vim"
install_or_skip "brew install zsh" "zsh"

install_or_skip "brew install fd" "fd"
install_or_skip "brew install rg" "rg"
install_or_skip "brew install bat" "bat"
install_or_skip "brew install exa" "exa"

install_or_skip "brew install lazygit" "lazygit"

# nerd-font
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
brew install --cask font-noto-nerd-font
