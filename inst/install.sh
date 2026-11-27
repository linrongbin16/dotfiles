#!/usr/bin/env zsh

set -Eeuo pipefail

# `./install` computed what this machine is and exported it, so it survives the
# `exec` into this shell. Check rather than re-derive: a missing one means this
# file was started some other way, and the install would otherwise run against
# an empty architecture.
: "${DOTFILES_HOME:?DOTFILES_HOME is not set - start the installation with ./install}"
: "${OS:?OS is not set - start the installation with ./install}"
: "${DOTFILES_ARCH:?DOTFILES_ARCH is not set - start the installation with ./install}"
: "${IS_ARM:?IS_ARM is not set - start the installation with ./install}"
: "${IS_MAC:?IS_MAC is not set - start the installation with ./install}"

. "$DOTFILES_HOME/inst/util.sh"

# Installed once, after `util.sh` defines `report_failure`. Covers the bare
# commands in `inst/apt.sh` and `inst/brew.sh` too, which are just as likely to
# fail as anything wrapped in `install()`.
trap 'report_failure' ERR

core_deps() {
  case "$OS" in
  Linux)
    . "$DOTFILES_HOME/inst/apt.sh"
    ;;
  Darwin)
    . "$DOTFILES_HOME/inst/brew.sh"
    ;;
  *)
    info "$OS is not supported, exit..."
    exit 1
    ;;
  esac
}

# Point the git credential helper at `gh`, so `git pull` / `git push` over
# HTTPS authenticate with the token `gh` already stores (its login, or the
# system keyring) instead of asking for a password.
#
# `gh auth setup-git` writes the absolute path of the `gh` binary that ran it.
# That path moves on an upgrade (`/opt/homebrew/Cellar/gh/<version>/...`, a
# different install prefix), and the stale copy in `.gitconfig` then makes
# every HTTPS fetch fail with "could not read Password". The bare `gh` below is
# resolved through PATH on each call instead.
#
# The empty helper resets the list first: git tries the helpers in order, and
# one left behind by an older setup would otherwise shadow the `gh` one.
#
# `github.user` is deliberately not set here: `git config --global` appends to
# the end of `~/.gitconfig`, so a global value would override the per-directory
# `includeIf` sections that the `gh` wrapper in dotfiles.sh reads.
set_github_credential_helper() {
  # Fail here, with the reason, rather than writing a helper that no `git`
  # invocation can run.
  if ! command -v gh >/dev/null 2>&1; then
    info "'gh' is not on PATH, cannot configure the git credential helper"
    return 1
  fi

  local gh_host key
  for gh_host in github.com gist.github.com; do
    key="credential.https://${gh_host}.helper"
    git config --global --replace-all "$key" ''
    git config --global --add "$key" '!gh auth git-credential'
  done
}

git_configs() {
  git config --global user.email "linrongbin16@outlook.com"
  git config --global user.name "linrongbin16"
  git config --global pull.rebase false
  git config --global init.defaultBranch main

  set_github_credential_helper
}

go_deps() {
  install "go install github.com/jesseduffield/lazygit@latest" "lazygit"
  install "go install github.com/umlx5h/gtrash@latest" "gtrash"
}

# rust
rust_deps() {
  export PATH="$HOME/.cargo/bin:$PATH"

  install "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" "rustup"

  if ! rustc --version >/dev/null 2>&1 || ! cargo --version >/dev/null 2>&1; then
    info "install 'rustc/cargo' with: 'rustup default stable'"
    rustup default stable
    info "install 'rustc/cargo' with: 'rustup default stable' - done"
  else
    skip_info "rustc/cargo"
  fi

  install "curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash" "cargo-binstall"

  install "cargo binstall -y fd-find" "fd"
  install "cargo binstall -y ripgrep" "rg"
  install "cargo binstall -y --locked bat" "bat"
  install "cargo binstall -y eza" "eza"
  install "cargo binstall -y --locked rmz" "rmz"
  install "cargo binstall -y --locked cpz" "cpz"
  install "cargo binstall -y --locked tree-sitter-cli" "tree-sitter"
  install "cargo binstall -y --locked bob-nvim" "bob"

  # `bob use` asks whether to add its `nvim-bin` to `$PATH`, and it waits 120
  # seconds for an answer. Closing stdin is not enough to skip that: bob only
  # asks when *both* stdout and stderr are terminals, so redirecting stdin still
  # hangs the install on a real terminal. Piping stdout through `cat` turns it
  # into a pipe and takes bob down its non-interactive branch, which records the
  # answer in its config and returns without touching any rc file. `pipefail` is
  # set, so a failed download still fails the install. `dotfiles.sh` already
  # puts `nvim-bin` on `$PATH`, so nothing is lost by not letting bob do it.
  install "bob use stable </dev/null | cat" "nvim"
}

prompt_deps() {
  # git-prompt
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.zsh"
  if [ ! -d "$HOME/.zsh/git-prompt.zsh" ]; then
    git clone --depth=1 https://github.com/woefe/git-prompt.zsh $HOME/.zsh/git-prompt.zsh
  fi

  # atuin
  install "curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive" "atuin"
  mkdir -p $HOME/.atuin
  if [ ! -f "$HOME/.atuin/config.toml" ]; then
    cp "$DOTFILES_HOME/atuin.toml" "$HOME/.atuin/config.toml"
  fi
}

ghostty_configs() {
  mkdir -p "$HOME/.config"
  if [ -d "$HOME/.config/ghostty" ]; then
    rm -rf $HOME/.config/ghostty
  fi
  if [ "$IS_MAC" = "1" ]; then
    ln -s "$DOTFILES_HOME/ghostty_mac" "$HOME/.config/ghostty"
  else
    ln -s "$DOTFILES_HOME/ghostty_unix" "$HOME/.config/ghostty"
  fi

  touch "$HOME/.config/ghostty/ghostty-custom"
}

install_ai_agents() {
  install "npm install --prefix=$HOME/.local/ -g pnpm" "pnpm"
  install "npm install --prefix=$HOME/.local/ -g '@deepseek-ai/dsh'" "dsh"
  install "curl -fsSL https://claude.ai/install.sh | bash" "claude"
  install "curl -fsSL https://chatgpt.com/codex/install.sh | sh" "codex"
}

# Install skills in `dsh-skills/` into `~/.dsh/skills`.
dsh_skills() {
  local source_dir="$DOTFILES_HOME/dsh-skills"
  local target_dir="$HOME/.dsh/skills"

  if [ ! -d "$source_dir" ]; then
    info "'$source_dir' is not a directory, skip..."
    return 0
  fi

  mkdir -p "$target_dir"

  local skill name target
  while IFS= read -r skill; do
    # `find` prints nothing when the directory only holds `.gitkeep`, and the
    # here-string below then yields one empty line.
    [ -n "$skill" ] || continue

    name="$(basename "$skill")"
    target="$target_dir/$name"

    # A link from a previous run already points at this checkout, so there is
    # nothing to redo.
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$skill" ]; then
      skip_info "$name"
      continue
    fi

    # Replace whatever is in the way (an older link, or a real directory from a
    # manual install) so the repository stays the source of truth. `rm -rf` on
    # a link removes the link itself, not the directory it points at.
    if [ -e "$target" ] || [ -L "$target" ]; then
      rm -rf "$target"
    fi

    ln -s "$skill" "$target"
    info "link '$skill' to '$target' - done"
  done <<EOF
$(find "$source_dir" -mindepth 1 -maxdepth 1 -type d)
EOF
}

profile_configs() {
  local line='[ -f ~/.dotfiles/dotfiles.sh ] && source ~/.dotfiles/dotfiles.sh'
  local zshrc="$HOME/.zshrc"

  # search if the `line` already exists and avoid duplication.
  if grep -qxF "$line" "$zshrc" 2>/dev/null; then
    info "'$zshrc' already sources dotfiles.sh, skip..."
    return 0
  fi

  if ! printf '\n%s\n%s\n' '# dotfiles' "$line" >>"$zshrc"; then
    info "failed to append to '$zshrc'"
    # `report_failure` clears the `return` statement as noise, which would leave
    # it printing a pointless "a command failed" after this message.
    DOTFILES_FAILURE_REPORTED=1
    return 1
  fi
}

main() {
  core_deps
  go_deps
  rust_deps
  prompt_deps
  git_configs
  ghostty_configs
  install_ai_agents
  dsh_skills
  profile_configs
  info "done"
}

main
