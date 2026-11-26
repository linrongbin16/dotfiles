#!/bin/zsh

# Sourced by `.zshrc`, and safe to source from `bash` as well. zsh is the
# primary target: the blocks that need it (`git-prompt.zsh`, `bindkey`,
# `setopt`) are skipped instead of emulated, so the aliases, PATH entries and
# `TERM` below still apply to bash.

# performance
# Apple M1 chip is 61440 by default; fall back to the classic 10240
ulimit -n 61440 2>/dev/null || ulimit -n 10240
ulimit -u 2660

# Which shell is sourcing this file, not which one is the login shell: `$SHELL`
# is still `/bin/zsh` inside a bash subshell, where `bindkey` does not exist.
if [ -n "${ZSH_VERSION:-}" ]; then
  DOTFILES_SHELL=zsh
else
  DOTFILES_SHELL=bash
fi

# ls
alias l="eza -lh"
alias ll="eza -alh"

# lazygit
alias lg="lazygit"

# git
alias gs="git status"
alias gp="git pull"
alias gP="git push"
alias ga="git add"

# gh
#
# Use the `gh` account that belongs to the repository. `github.user` is read
# from the git config, so an `includeIf` section can override it per directory
# the same way `user.name` / `user.email` are switched:
#
#   [includeIf "gitdir:~/work/"]
#     path = ~/.gitconfig-work
#
# The wrapper fetches that account's token and hands it to `gh` through
# `GH_TOKEN` for this invocation only, leaving the shell's active account
# untouched. `command gh` is deliberate: a bare `gh` here would call this
# function again.
#
# `printf ... >&2` rather than zsh's `print -u2`: this file is sourced by bash
# too, where `print` does not exist.
gh() {
  local u token
  u=$(command git config github.user 2>/dev/null)
  if [ -n "$u" ]; then
    if token=$(command gh auth token --user "$u" 2>/dev/null) && [ -n "$token" ]; then
      GH_TOKEN="$token" command gh "$@"
      return
    fi
    printf '%s\n' "gh: no stored login for '$u' (github.user), using active account; run: gh auth login" >&2
  fi
  command gh "$@"
}

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# go
export GOPATH="$HOME/go"  # user workspace
export PATH="$PATH:$GOPATH/bin"

# deno
if [ -f "$HOME/.deno/env" ]; then
  . "$HOME/.deno/env"
fi

# bun
if [ -d "$HOME/.bun/bin" ]; then
  export PATH="$PATH:$HOME/.bun/bin"
fi

# bob-nvim
if [ -d "$HOME/.local/share/bob/nvim-bin" ]; then
  export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"
fi
if [ -d "$HOME/Library/Application Support/bob/nvim-bin" ]; then
  export PATH="$PATH:$HOME/Library/Application Support/bob/nvim-bin"
fi

# local bins
export PATH="$HOME/.local/bin:$PATH"

# mise
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate "$DOTFILES_SHELL")"
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  # eval "$(zoxide init --cmd cd "$DOTFILES_SHELL")"
  eval "$(zoxide init "$DOTFILES_SHELL")"
fi

# git-prompt.zsh {{{
if [ "$DOTFILES_SHELL" = "zsh" ] && [ -f "$HOME/.zsh/git-prompt.zsh/git-prompt.zsh" ]; then
  source $HOME/.zsh/git-prompt.zsh/git-prompt.zsh

  # ZSH_THEME_GIT_PROMPT_PREFIX="["
  # ZSH_THEME_GIT_PROMPT_SUFFIX="] "
  # ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
  ZSH_THEME_GIT_PROMPT_PREFIX=""
  ZSH_THEME_GIT_PROMPT_SUFFIX=""
  ZSH_THEME_GIT_PROMPT_SEPARATOR=" "
  ZSH_THEME_GIT_PROMPT_DETACHED="%{$fg_bold[cyan]%}:"
  ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[magenta]%}"
  ZSH_THEME_GIT_PROMPT_UPSTREAM_PREFIX="%{$fg[red]%}(%{$fg[yellow]%}"
  ZSH_THEME_GIT_PROMPT_UPSTREAM_SUFFIX="%{$fg[red]%})"
  ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[red]%}x"
  ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[green]%}o"
  ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$fg[red]%}+"
  ZSH_THEME_GIT_PROMPT_BEHIND="↓"
  ZSH_THEME_GIT_PROMPT_AHEAD="↑"
  ZSH_THEME_GIT_PROMPT_UNTRACKED="…"
  ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}✓"
  ZSH_THEME_GIT_PROMPT_UPSTREAM_SYMBOL="%{$fg_bold[yellow]%}⟳"
  ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[blue]%}⚑"

  # `$(gitprompt)` is only expanded when PROMPT_SUBST is on. The plugin sets it
  # for its own prompt, but the prompt is built here, so ask for it here.
  setopt PROMPT_SUBST

  PROMPT=$'%F{blue}%~%f %b$(gitprompt)%f
%(12V.%F{242}%12v%f .)%(?.%F{cyan}.%F{red})❯%f '

  RPROMPT=''
fi
# git-prompt.zsh }}}

# xterm
export TERM="xterm-256color"

# zsh disable vi-mode, enforce emacs-mode
if [ "$DOTFILES_SHELL" = "zsh" ]; then
  bindkey -e
fi
