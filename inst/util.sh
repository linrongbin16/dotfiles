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

# Target that `install()` is currently working on, or empty when the failing
# command came from somewhere else (a bare `apt-get` at the top level of
# `inst/apt.sh`, for instance).
DOTFILES_CURRENT_TARGET=""

# ERR trap handler, installed once by `install`. Reports what broke, then exits
# non-zero so the script stops either way.
#
# Without this, `set -e` kills the script silently: the reader sees the last
# line of output and has no idea which command failed, let alone which tool it
# was installing.
report_failure() {
  local status=$?
  # `exit 0` would turn a failure into success; `set -e` only fires on non-zero,
  # but stay explicit in case this is ever called by hand.
  if [ "$status" -eq 0 ]; then
    status=1
  fi

  # A function that returns non-zero has already said what went wrong (see
  # `profile_configs`), so naming the `return` statement itself would only add
  # noise like "'return 1' failed (exit 1)". Still name the target when there is
  # one - `install "some_installer" "tool"` is exactly the case where the
  # installer's own message may not say which tool it was.
  case "$BASH_COMMAND" in
  return* | exit*)
    if [ -n "$DOTFILES_CURRENT_TARGET" ]; then
      info "install '$DOTFILES_CURRENT_TARGET' - failed (exit $status)"
    fi
    exit "$status"
    ;;
  esac

  if [ -n "$DOTFILES_CURRENT_TARGET" ]; then
    info "install '$DOTFILES_CURRENT_TARGET' with: '$BASH_COMMAND' - failed (exit $status)"
  else
    info "'$BASH_COMMAND' failed (exit $status)"
  fi
  exit "$status"
}

install() {
  local command="$1"
  local target="$2"
  if type "$target" >/dev/null 2>&1; then
    skip_info $target
    return 0
  fi

  info "install '$target' with: '$command'"
  # Run the command bare - not inside `if`, and not behind `||`.
  #
  # Both of those would disable errexit for everything the command runs, so a
  # multi-step installer (say `install_git`, which chains several apt calls)
  # would keep going after its first failure and report success as long as its
  # last step happened to work. `set -e` can only fast-fail through here if this
  # line is left unprotected.
  DOTFILES_CURRENT_TARGET="$target"
  eval "$command"
  DOTFILES_CURRENT_TARGET=""
  info "install '$target' with: '$command' - done"
}
