#!/usr/bin/env bash

# Tmux session for VA dev repos with agent windows
# Creates a session with 4 windows: cursor-agent, codex, terminal, nvim

SESSION_NAME="$(basename "$PWD")-va-dev"

# Check if session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
  # Window 1: cursor-agent
  tmux new-session -d -s "$SESSION_NAME" -n "cursor-agent"
  tmux send-keys -t "$SESSION_NAME:1" "cursor-agent" C-m

  # Window 2: codex
  tmux new-window -t "$SESSION_NAME:2" -n "codex"
  tmux send-keys -t "$SESSION_NAME:2" "codex" C-m

  # Window 3: terminal
  tmux new-window -t "$SESSION_NAME:3" -n "terminal"

  # Window 4: nvim
  tmux new-window -t "$SESSION_NAME:4" -n "nvim"
  tmux send-keys -t "$SESSION_NAME:4" "nvim ." C-m

  # Select first window by default
  tmux select-window -t "$SESSION_NAME:1"
fi

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
