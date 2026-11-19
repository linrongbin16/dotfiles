#!/bin/bash

# set -x

info "install deps with brew"

brew update

install "brew install lld" "lld"
install "brew install autoconf" "autoconf"
install "brew install automake" "automake"
install "brew install pkg-config" "pkg-config"
install "brew install cmake" "cmake"
install "brew install openssl" "$(brew --prefix openssl)/bin/openssl"

install "brew install git" "git"
install "brew install gh" "gh"
install "brew install curl" "curl"
install "brew install wget" "wget"

install "brew install gzip" "gzip"
install "brew install p7zip" "7z"
install "brew install unzip" "unzip"

install "brew install python3" "python3"

install "brew install node" "node"
install "brew install deno" "deno"
install "brew install oven-sh/bun/bun" "bun"

install "brew install go" "go"
# `macos-trash` is keg-only, so it is never linked into the brew prefix and
# `command -v trash` cannot see it. Ask brew where the keg is instead.
install "brew install macos-trash" "$(brew --prefix macos-trash)/bin/trash"
install "brew install zoxide" "zoxide"
install "brew install fzf" "fzf"
install "brew install lazygit" "lazygit"
install "brew install moor" "moor"
install "brew install ripgrep" "rg"
install "brew install bat" "bat"
install "brew install fd" "fd"
install "brew install eza" "eza"
install "brew install tree-sitter-cli" "tree-sitter"
install "brew install k1LoW/tap/mo" "mo"

install "brew install neovim" "nvim"
