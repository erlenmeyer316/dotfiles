#!/usr/bin/env bash

if [ -f "$HOME/.fzf.bash" ]; then
  source $HOME/.fzf.bash
else
  if [ $(command -v "fzf") ]; then
    if [ -f /usr/share/bash-completion/completions/fzf ]; then
      source /usr/share/bash-completion/completions/fzf
    fi

    if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
      source /usr/share/doc/fzf/examples/key-bindings.bash
    fi
  fi
fi
