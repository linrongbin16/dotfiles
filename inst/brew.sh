#!/bin/bash

# set -x

info "install deps with brew"

brew update

# c/c++ toolchain
brew install lld autoconf automake pkg-config cmake

# ssh/ssl
install "brew install openssl" "$(brew --prefix openssl)/bin/openssl"

# git
install "brew install git" "git"
install "brew install gh" "gh"

# cli tools
brew install curl wget gzip p7zip unzip

# python
install "brew install python3" "python3"

# node/deno/bun
install "brew install node" "node"
install "brew install deno" "deno"
install "brew install oven-sh/bun/bun" "bun"

# go
install "brew install go" "go"

# trash
install "brew install macos-trash" "$(brew --prefix macos-trash)/bin/trash"

# develop tools
brew install zoxide fzf lazygit moor ripgrep bat fd eza tree-sitter-cli k1LoW/tap/mo mise

# neovim
install "brew install neovim" "nvim"
