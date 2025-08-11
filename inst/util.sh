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

install_deno() {
  curl -fsSL https://deno.land/install.sh | sh -s -- -y
}

install_bun() {
  curl -fsSL https://bun.com/install | bash
}

install_atuin() {
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
}

install_mise() {
  curl https://mise.run | sh
}
