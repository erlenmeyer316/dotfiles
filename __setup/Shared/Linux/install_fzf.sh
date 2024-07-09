#!/usr/bin/env bash
GO_CMD=go
FZF_CMD=fzf

if command -v -- "$GO_CMD" > /dev/null 2>&1; then
   if ! command -v -- "$FZF_CMD" > /dev/null 2>&1; then
      go install github.com/junegunn/fzf@latest
   fi
else
   echo "$FZF_CMD depends on $GO_CMD. Please install $GO_CMD"
fi

