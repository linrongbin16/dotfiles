#!/bin/bash

DEPS=$1
source $DEPS/util.sh

message "install dependencies with dnf"
sudo dnf check-update

install_or_skip "sudo dnf group install -y \"Development Tools\"" "gcc"
install_or_skip "sudo dnf group install -y \"Development Tools\"" "make"
install_or_skip "sudo dnf install -y autoconf" "autoconf"
install_or_skip "sudo dnf install -y automake" "automake"
install_or_skip "sudo dnf install -y pkg-config" "pkg-config"
install_or_skip "sudo dnf install -y cmake" "cmake"

install_or_skip "sudo dnf install -y git" "git"
install_or_skip "sudo dnf install -y curl" "curl"
install_or_skip "sudo dnf install -y wget" "wget"

install_or_skip "sudo dnf install -y unzip" "unzip"
install_or_skip "sudo dnf install -y gzip" "gzip"
install_or_skip "sudo dnf install -y p7zip" "7z"
install_or_skip "sudo dnf install -y atool" "atool"

install_or_skip "sudo dnf install -y xsel" "xsel"
install_or_skip "sudo dnf install -y xclip" "xclip"
install_or_skip "sudo dnf install -y wl-clipboard" "wl-copy"

install_or_skip "sudo dnf install -y python3 python3-devel python3-pip python3-docutils" "python3"

install_or_skip "sudo dnf install -y vim" "vim"
install_or_skip "sudo dnf install -y zsh" "zsh"
