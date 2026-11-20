#!/bin/bash

# Sourced from `inst/install.sh`, fail loudly instead of expanding to empty
# strings when this file is sourced on its own.
: "${DOTFILES_ARCH:?DOTFILES_ARCH is not set - source this file from inst/install.sh}"
: "${IS_ARM:?IS_ARM is not set - source this file from inst/install.sh}"

install_nodejs() {
  # https://github.com/nodesource/distributions
  sudo apt-get install -y curl
  curl -fsSL https://deb.nodesource.com/setup_lts.x -o nodesource_setup.sh
  sudo -E bash nodesource_setup.sh
  sudo apt-get -q update
  sudo apt-get -q -y install nodejs
}

install_git() {
  sudo apt-add-repository -y ppa:git-core/ppa
  sudo apt-get -q -q -y update
  sudo apt-get install -q -y git
}

install_gh() {
  (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y) ) &&
    sudo mkdir -p -m 755 /etc/apt/keyrings &&
    out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg &&
    cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null &&
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg &&
    sudo mkdir -p -m 755 /etc/apt/sources.list.d &&
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
    sudo apt update &&
    sudo apt install gh -y
}

install_go() {
  sudo add-apt-repository -y ppa:longsleep/golang-backports
  sudo apt update
  sudo apt-get install -q -y golang-go
}

install_eza() {
  sudo apt update
  sudo apt install -y gpg
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
}

install_bat() {
  sudo apt-get install -q -y bat
  # -f/-n make this safe to re-run (and under CI's `set -e`)
  sudo ln -sfn /usr/bin/batcat /usr/bin/bat
}

install_fd() {
  sudo apt-get install -q -y fd-find
  sudo ln -sfn /usr/bin/fdfind /usr/bin/fd
}

install_neovim() {
  sudo apt install -y snapd
  sudo snap install nvim --classic
}

install_mo() {
  # https://github.com/k1LoW/mo
  local tag version
  tag="$(basename "$(curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/k1LoW/mo/releases/latest)")"
  version="${tag#v}"
  curl -fsSL -O "https://github.com/k1LoW/mo/releases/download/${tag}/mo_${version}-1_${DOTFILES_ARCH}.deb"
  sudo apt-get install -q -y "./mo_${version}-1_${DOTFILES_ARCH}.deb"
}

info "install deps with apt"
info "arch: $DOTFILES_ARCH, arm: $IS_ARM"

sudo apt-get -q -y update

# c/c++ toolchain
sudo apt-get install -q -y build-essential llvm llvm-dev clang \
  lld mold autoconf automake pkg-config cmake \
  libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev

# ssh/ssl
sudo apt-get install -q -y libssl-dev openssl openssh-client openssh-server

# git
install "install_git" "git"
install "install_gh" "gh"

# cli tools
sudo apt-get install -q -y curl wget gzip 7zip unzip xsel xclip

# python
sudo apt-get install -q -y python3 python3-dev python3-venv python3-pip python3-docutils

# node/deno/bun
install "install_nodejs" "node"
install "install_nodejs" "npm"
install "curl -fsSL https://deno.land/install.sh | sh -s -- -y" "deno"
install "curl -fsSL https://bun.com/install | bash" "bun"

# go
install "install_go" "go"

# develop tools
sudo apt-get install -q -y lazygit fzf ripgrep zoxide
install "install_bat" "bat"
install "install_fd" "fd"
install "install_eza" "eza"
install "install_mo" "mo"
install "curl -fsSL https://mise.run | MISE_INSTALL_HELP=0 sh" "mise"

# neovim
install "install_neovim" "nvim"
