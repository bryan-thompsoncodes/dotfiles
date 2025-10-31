#!/usr/bin/env bash

# Tmux session for opencode and editor
# Creates a session with 3 windows: opencode, terminal, nvim

SESSION_NAME="$(basename "$PWD")-editor"

# Check if session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
  # Create new session with first window (opencode)
  tmux new-session -d -s "$SESSION_NAME" -n "opencode"
  tmux send-keys -t "$SESSION_NAME:1" "opencode" C-m

  # Window 2: terminal
  tmux new-window -t "$SESSION_NAME:2" -n "terminal"

  # Window 3: nvim
  tmux new-window -t "$SESSION_NAME:3" -n "nvim"
  tmux send-keys -t "$SESSION_NAME:3" "nvim ." C-m

  # Select first window by default
  tmux select-window -t "$SESSION_NAME:1"
fi

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
