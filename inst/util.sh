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

# Targets that failed to install. `install()` appends to these and
# `report_failures()` turns them into a non-zero exit code at the end of `main`.
# Plain strings rather than an array: macOS ships bash 3.2, where expanding an
# empty array under `set -u` (CI runs `bash -euxo pipefail`) aborts the script.
DOTFILES_FAILURES=0
DOTFILES_FAILED_TARGETS=""

record_failure() {
  DOTFILES_FAILURES=$((DOTFILES_FAILURES + 1))
  if [ -z "$DOTFILES_FAILED_TARGETS" ]; then
    DOTFILES_FAILED_TARGETS="$1"
  else
    DOTFILES_FAILED_TARGETS="$DOTFILES_FAILED_TARGETS $1"
  fi
}

# Print every target that failed and return non-zero so the caller can exit 1.
# Kept as a separate step so that one broken tool doesn't hide the others.
report_failures() {
  if [ "$DOTFILES_FAILURES" -eq 0 ]; then
    return 0
  fi

  info "$DOTFILES_FAILURES target(s) failed to install: $DOTFILES_FAILED_TARGETS"
  info "re-run './install' after fixing the cause, or install them by hand"
  return 1
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
  # Record and keep going instead of returning the failure: the remaining
  # targets still deserve a try, and `report_failures()` reports them all at
  # once. Returning non-zero here would make `bash -e` (CI) stop at the first
  # failure while a plain `./install` carries on, so the two runs would end up
  # installing different things.
  record_failure "$target"
  return 0
}
