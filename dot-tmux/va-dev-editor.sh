#!/usr/bin/env bash

# Tmux session for VA dev repos with agent windows
# Creates a session with 4 windows: opencode, claude code, terminal, nvim

# Ensure we have a proper TTY for tmux
if [[ ! -t 0 ]]; then
  exec </dev/tty
fi

SESSION_NAME="$(basename "$PWD")-va-dev"

# Check if session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
  tmux new-session -d -s "$SESSION_NAME" -n "opencode"
  tmux send-keys -t "$SESSION_NAME:1" "opencode" C-m

  tmux new-window -t "$SESSION_NAME:2" -n "claude code"
  tmux send-keys -t "$SESSION_NAME:2" "claude ." C-m

  tmux new-window -t "$SESSION_NAME:3" -n "terminal"

  tmux new-window -t "$SESSION_NAME:4" -n "nvim"
  tmux send-keys -t "$SESSION_NAME:4" "nvim ." C-m

  # Select first window by default
  tmux select-window -t "$SESSION_NAME:1"
fi

# Attach to the session (or switch if already in tmux)
if [[ -n "$TMUX" ]]; then
  tmux switch-client -t "$SESSION_NAME"
else
  tmux attach-session -t "$SESSION_NAME"
fi
