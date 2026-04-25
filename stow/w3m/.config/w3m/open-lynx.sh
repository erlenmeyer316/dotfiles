#!/usr/bin/env bash
# Open URL in lynx in a new tmux window (so w3m stays open)
# $1 is the URL passed by w3m via %s in extbrowser config
tmux new-window "lynx '$1'"
