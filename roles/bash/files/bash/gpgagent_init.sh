#!/usr/bin/env bash

#gpg_pid_file="$HOME/.config/gpg-agent.pid"
#if [ -z "$GPG_AGENT_ID" ]; then
# no PID exported, try to get it from pidfile
#  GPG_AGENT_PID=$(cat "$gpg_pid_file")
#fi

#if ! kill -0 $GPG_AGENT_PID &>/dev/null; then
# the agent is not running, start it
#  >&2 echo "Starting GPG agent, since it's not running; this can take a moment"
#  eval "$(gpg-agent --daemon --allow-preset-passphrase)"
#  echo "$GPG_AGENT_PID" >"$gpg_pid_file"
#  >&2 echo "Started gpg-agent"
#else
#>&2 echo "gpg-agent already running ($GPG_AGENT_PID)"
#fi
#export GPG_AGENT_PID
