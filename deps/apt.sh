#!/bin/bash

DEPS=$1
source $DEPS/util.sh

message "install dependencies with apt"
sudo apt-get update

install_or_skip "sudo apt-get install -y build-essential" "gcc"
install_or_skip "sudo apt-get install -y build-essential" "make"
install_or_skip "sudo apt-get install -y autoconf" "autoconf"
install_or_skip "sudo apt-get install -y automake" "automake"
install_or_skip "sudo apt-get install -y pkg-config" "pkg-config"
install_or_skip "sudo apt-get install -y cmake" "cmake"

# install_or_skip "sudo apt-get install -y git" "git"
# install latest git from ppa
sudo apt-add-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git
install_or_skip "sudo apt-get install -y curl" "curl"
install_or_skip "sudo apt-get install -y wget" "wget"

install_or_skip "sudo apt-get install -y gzip" "gzip"
install_or_skip "sudo apt-get install -y p7zip" "7z"
install_or_skip "sudo apt-get install -y unzip" "unzip"
install_or_skip "sudo apt-get install -y unrar" "unrar"
install_or_skip "sudo apt-get install -y atool" "atool"

install_or_skip "sudo apt-get install -y xsel" "xsel"
install_or_skip "sudo apt-get install -y xclip" "xclip"

install_or_skip "sudo apt-get install -y python3 python3-dev python3-venv python3-pip python3-docutils" "python3"
install_or_skip "sudo apt-get install -y python3 python3-dev python3-venv python3-pip python3-docutils" "pip3"

install_or_skip "sudo apt-get install -y vim" "vim"
install_or_skip "sudo apt-get install -y zsh" "zsh"

