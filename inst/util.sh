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
