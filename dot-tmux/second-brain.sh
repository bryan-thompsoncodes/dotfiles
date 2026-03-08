#!/usr/bin/env bash

# Tmux session for second-brain with opencode (Muse agent)
# Creates a session with opencode running in ~/notes/second-brain

# Ensure we have a proper TTY for tmux
if [[ ! -t 0 ]]; then
  exec </dev/tty
fi

SESSION_NAME="2nd-Brain"
PROJECT_DIR="$HOME/notes/second-brain"

# Verify the directory exists
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: $PROJECT_DIR does not exist"
  exit 1
fi

# Check if session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
  # Create new session with opencode window
  tmux new-session -d -s "$SESSION_NAME" -n "Muse" -c "$PROJECT_DIR"
  tmux send-keys -t "$SESSION_NAME:1" "opencode --agent muse" C-m
fi

# Attach to the session (or switch if already in tmux)
if [[ -n "$TMUX" ]]; then
  tmux switch-client -t "$SESSION_NAME"
else
  tmux attach-session -t "$SESSION_NAME"
fi
