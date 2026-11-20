#!/bin/bash

# set -x

info "install deps with brew"

# Kept for fresh machines and local runs: `brew install` reads the formula
# metadata this refreshes. In CI the macOS runner image already updated
# Homebrew during provisioning, so this is a no-op ("Already up-to-date").
brew update

# One `brew install` for everything that is missing. Homebrew resolves the
# dependency graph and fetches the bottles in one transaction instead of
# starting a Ruby process per formula; keg-only tools are checked through their
# absolute path (`openssl`, `macos-trash`).
brew_install_missing \
  lld:lld \
  autoconf:autoconf \
  automake:automake \
  pkg-config:pkg-config \
  cmake:cmake \
  "openssl:$(brew --prefix openssl)/bin/openssl" \
  git:git \
  gh:gh \
  curl:curl \
  wget:wget \
  gzip:gzip \
  p7zip:7z \
  unzip:unzip \
  python3:python3 \
  node:node \
  deno:deno \
  oven-sh/bun/bun:bun \
  go:go \
  "macos-trash:$(brew --prefix macos-trash)/bin/trash" \
  zoxide:zoxide \
  fzf:fzf \
  lazygit:lazygit \
  moor:moor \
  ripgrep:rg \
  bat:bat \
  fd:fd \
  eza:eza \
  tree-sitter-cli:tree-sitter \
  k1LoW/tap/mo:mo \
  mise:mise \
  neovim:nvim
