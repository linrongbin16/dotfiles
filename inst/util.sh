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
  local status=0
  if type "$target" >/dev/null 2>&1; then
    skip_info $target
    return 0
  fi

  info "install '$target' with: '$command'"
  # Run inside `if` so that errexit (`bash -e`, used by CI) doesn't abort
  # before we get a chance to report which command failed.
  if eval "$command"; then
    info "install '$target' with: '$command' - done"
    return 0
  else
    status=$?
  fi

  info "install '$target' with: '$command' - failed (exit $status)"
  return "$status"
}
