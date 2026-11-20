#!/bin/bash

# set -x

# Platform detection is done once by `install` (see the top of that file):
# `OS_ARCH` is the `uname -m` name, `ARCH` the dpkg package architecture and
# `IS_ARM` the 0/1 flag. Fail loudly instead of expanding to empty strings
# when this file is sourced without `install`.
: "${ARCH:?ARCH is not set - source this file from install}"
: "${IS_ARM:?IS_ARM is not set - source this file from install}"

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
  # The package lists are already fresh here, so a missing wget only needs the
  # install, not another update.
  (type -p wget >/dev/null || sudo apt install -y wget) &&
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
  # The package lists were refreshed at the top of this file; only the new
  # eza repository needs a second update, further down.
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
  curl -fsSL -O "https://github.com/k1LoW/mo/releases/download/${tag}/mo_${version}-1_${ARCH}.deb"
  sudo apt-get install -q -y "./mo_${version}-1_${ARCH}.deb"
}

info "install deps with apt"
info "arch: $ARCH, arm: $IS_ARM"

# Refresh the package lists once for the whole script. Repositories added
# later (git/gh/go/eza) still refresh them again after the new source is in
# place, since those entries did not exist for this update.
sudo apt-get -q -y update

# One transaction for the base toolchain. `build-essential` already pulls in
# `g++`, and `cmake`/`pkg-config` used to be listed twice; apt resolves the
# whole set once instead of once per package.
sudo apt-get install -q -y \
  build-essential llvm llvm-dev clang lld mold \
  libssl-dev openssl openssh-client openssh-server \
  cmake pkg-config libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev \
  python3

install "sudo apt-get install -q -y autoconf" "autoconf"
install "sudo apt-get install -q -y automake" "automake"

install "install_git" "git"
install "install_gh" "gh"

# Everything below comes from the distribution archive, so one `apt-get
# install` can cover all of it. Each package is still skipped when its command
# is already on PATH.
apt_install_missing \
  curl:curl \
  wget:wget \
  gzip:gzip \
  7zip:7z \
  unzip:unzip \
  xsel:xsel \
  xclip:xclip \
  zoxide:zoxide \
  fzf:fzf \
  ripgrep:rg

# python3 and its development packages are one unit: `pip3` without them is
# useless, so both checks install the same set.
install "sudo apt-get install -q -y python3 python3-dev python3-venv python3-pip python3-docutils" "python3"
install "sudo apt-get install -q -y python3 python3-dev python3-venv python3-pip python3-docutils" "pip3"

install "install_nodejs" "node"
install "install_nodejs" "npm"

install "install_go" "go"

install "install_bat" "bat"
install "install_fd" "fd"
install "install_eza" "eza"
install "install_mo" "mo"
install "curl -fsSL https://mise.run | MISE_INSTALL_HELP=0 sh" "mise"

install "install_neovim" "nvim"
