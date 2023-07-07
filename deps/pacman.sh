#!/bin/bash

DEPS=$1
source $DEPS/util.sh

message "install dependencies with pacman"
sudo pacman -Syy

install_or_skip "yes | sudo pacman -S base-devel" "gcc"
install_or_skip "yes | sudo pacman -S base-devel" "make"
install_or_skip "yes | sudo pacman -S autoconf" "autoconf"
install_or_skip "yes | sudo pacman -S automake" "automake"
install_or_skip "yes | sudo pacman -S pkg-config" "pkg-config"
install_or_skip "yes | sudo pacman -S cmake" "cmake"

install_or_skip "yes | sudo pacman -S git" "git"
install_or_skip "yes | sudo pacman -S curl" "curl"
install_or_skip "yes | sudo pacman -S wget" "wget"

install_or_skip "yes | sudo pacman -S unzip" "unzip"
install_or_skip "yes | sudo pacman -S gzip" "gzip"
install_or_skip "yes | sudo pacman -S p7zip" "7z"
install_or_skip "yes | sudo pacman -S atool" "atool"

install_or_skip "yes | sudo pacman -S xsel" "xsel"
install_or_skip "yes | sudo pacman -S xclip" "xclip"
install_or_skip "yes | sudo pacman -S wl-clipboard" "wl-copy"

install_or_skip "yes | sudo pacman -S python python-pip" "python3"

install_or_skip "yes | sudo pacman -S vim" "vim"
install_or_skip "yes | sudo pacman -S zsh" "zsh"
