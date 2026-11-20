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

# Set by a function that has already explained its own failure, so the handler
# below does not append a vague "a command failed" line after a specific
# message. Both shells need it: bash's `BASH_COMMAND` and zsh's DEBUG trap each
# name the `return` statement, which the handler clears as noise, leaving it
# with nothing to report but that generic line.
DOTFILES_FAILURE_REPORTED=0

# zsh has no `BASH_COMMAND`, so a DEBUG trap records each command as it starts
# and the handler reads the last one back. Without it, a failure that comes from
# a bare command in `inst/apt.sh` would be reported as an anonymous "a command
# failed", while bash names it. It also names the failing step inside a
# multi-step `install` command rather than the whole command string.
DOTFILES_LAST_COMMAND=""
if [ -n "${ZSH_VERSION:-}" ]; then
  trap 'DOTFILES_LAST_COMMAND=$ZSH_DEBUG_CMD' DEBUG
fi

# Failure handler, installed once by `install` as the `ERR` trap.
#
# Without this, `set -e` kills the script silently: the reader sees the last
# line of output and has no idea which command failed, let alone which tool it
# was installing.
#
# `$?` is read through the argument's default so it still holds the failing
# status: the `local` keyword would otherwise reset it. The variable is called
# `code` and not `status` because zsh treats `status` as a read-only special.
#
# `BASH_COMMAND` names the failing command under bash. Under zsh the DEBUG trap
# above stands in for it.
report_failure() {
  local code="${1:-$?}"
  local failed="${BASH_COMMAND:-${DOTFILES_LAST_COMMAND:-}}"

  # A function that returns non-zero has already said what went wrong (see
  # `profile_configs`), so naming the `return` statement itself would only add
  # noise like "'return 1' failed (exit 1)". Still name the target when there is
  # one - `install "some_installer" "tool"` is exactly the case where the
  # installer's own message may not say which tool it was.
  case "$failed" in
  return* | exit*) failed="" ;;
  esac

  if [ "$DOTFILES_FAILURE_REPORTED" = "1" ]; then
    exit "$code"
  fi

  if [ -n "$DOTFILES_CURRENT_TARGET" ]; then
    if [ -n "$failed" ]; then
      info "install '$DOTFILES_CURRENT_TARGET' with: '$failed' - failed (exit $code)"
    else
      info "install '$DOTFILES_CURRENT_TARGET' - failed (exit $code)"
    fi
  elif [ -n "$failed" ]; then
    info "'$failed' failed (exit $code)"
  else
    info "a command failed (exit $code)"
  fi
  exit "$code"
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

# Install several apt packages with one `apt-get install` call.
#
# Each argument is a `package:command` pair. A package is skipped when its
# command already resolves, exactly like `install()` would skip it. Batching
# matters because every `apt-get install` re-reads the package lists, resolves
# dependencies and runs dpkg's triggers (needrestart among them) once; on a
# cold machine that is a second or two per package, and a fresh machine needs a
# dozen of them.
#
# Packages that are renamed on Debian/Ubuntu (`bat` ships `batcat`, `fd` ships
# `fdfind`) keep their own `install_bat`/`install_fd` helpers, because the
# symlink has to be created after the package lands.
apt_install_missing() {
  local -a packages=()
  local pair package target
  for pair in "$@"; do
    package="${pair%%:*}"
    target="${pair#*:}"
    if type -p "$target" >/dev/null 2>&1; then
      skip_info "$target"
    else
      packages+=("$package")
    fi
  done
  if [ "${#packages[@]}" -eq 0 ]; then
    return 0
  fi

  local targets="${packages[*]}"
  info "install '$targets' with: 'sudo apt-get install -q -y'"
  DOTFILES_CURRENT_TARGET="$targets"
  sudo apt-get install -q -y "${packages[@]}"
  DOTFILES_CURRENT_TARGET=""
  info "install '$targets' with: 'sudo apt-get install -q -y' - done"
}

# The Homebrew counterpart of `apt_install_missing()`: one `brew install` for
# every missing formula, instead of one Ruby process per formula.
#
# Arguments are `formula:command` pairs. `command` may be an absolute path,
# which is how keg-only formulae are checked (`openssl`, `macos-trash`).
brew_install_missing() {
  local -a formulae=()
  local pair formula target
  for pair in "$@"; do
    formula="${pair%%:*}"
    target="${pair#*:}"
    if [ -x "$target" ] || type -p "$target" >/dev/null 2>&1; then
      skip_info "$target"
    else
      formulae+=("$formula")
    fi
  done
  if [ "${#formulae[@]}" -eq 0 ]; then
    return 0
  fi

  local targets="${formulae[*]}"
  info "install '$targets' with: 'brew install'"
  DOTFILES_CURRENT_TARGET="$targets"
  brew install "${formulae[@]}"
  DOTFILES_CURRENT_TARGET=""
  info "install '$targets' with: 'brew install' - done"
}
