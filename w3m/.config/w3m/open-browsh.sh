#!/usr/bin/env bash
# Open URL in browsh in a new tmux window
# browsh requires Firefox installed; it's CPU-heavy — use selectively
tmux new-window "browsh '$1'"
