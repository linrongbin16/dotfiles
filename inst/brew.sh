#!/bin/bash

# set -x

info "install deps with brew"

# Deliberately not an `install()` call: there is no formula to probe for, and
# passing `brew` as the target would skip forever because `type brew` always
# succeeds. A failure here is still reported by the ERR trap, as
# `'brew update' failed (exit N)`.
brew update

install "brew install lld" "lld"
install "brew install autoconf" "autoconf"
install "brew install automake" "automake"
install "brew install pkg-config" "pkg-config"
install "brew install cmake" "cmake"
# `openssl` and `ssh` also live in /usr/bin, so probing the bare names would
# report success before brew installed its own copy - and the two formulas have
# to be separate `install()` calls anyway. Probe the keg path instead.
install "brew install openssl" "$(brew --prefix openssl)/bin/openssl"
install "brew install openssh" "$(brew --prefix openssh)/bin/ssh"

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
install "brew install macos-trash" "/opt/homebrew/opt/macos-trash/bin/trash"
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
