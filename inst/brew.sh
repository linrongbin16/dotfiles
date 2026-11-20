#!/bin/bash

# set -x

info "install deps with brew"

brew update

# c/c++ toolchain
brew install lld autoconf automake pkg-config cmake

# ssh/ssl
brew install openssl

# git
brew install git gh

# cli tools
brew install curl wget gzip p7zip unzip

# python
brew install python3

# node/deno/bun
brew install node deno oven-sh/bun/bun

# go
brew install go

# trash
brew install macos-trash

# develop tools
brew install zoxide fzf lazygit ripgrep bat fd eza tree-sitter-cli k1LoW/tap/mo mise

# neovim
install "brew install neovim" "nvim"
