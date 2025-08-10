#!/bin/bash

# set -x

info() {
  local content="$*"
  printf "[dotfiles] - %s\n" "$content"
}

skip_info() {
  local old="$IFS"
  IFS='/'
  local target="'$*'"
  info "$target already exist, skip..."
  IFS=$old
}

install() {
  local command="$1"
  local target="$2"
  if ! type "$target" >/dev/null 2>&1; then
    info "install '$target' with: '$command'"
    eval "$command"
    info "install '$target' with: '$command' - done"
  else
    skip_info $target
  fi
}

install_go_for_linux() {
  git clone --depth=1 https://github.com/kerolloz/go-installer
  export GOROOT="$HOME/.go" # where go is installed
  export GOPATH="$HOME/go"  # user workspace
  bash ./go-installer/go.sh
  export PATH="$PATH:$GOROOT/bin"
  export PATH="$PATH:$GOPATH/bin"
}

install_fzf_for_linux() {
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --bin
  sudo cp ~/.fzf/bin/fzf /usr/local/bin/fzf
  fzf --version
}

install_moar() {
  go install github.com/walles/moar@latest
}

install_gtrash() {
  go install github.com/umlx5h/gtrash@latest
}

install_deno() {
  curl -fsSL https://deno.land/install.sh | sh -s -- -y
}

install_bun() {
  curl -fsSL https://bun.com/install | bash
}
