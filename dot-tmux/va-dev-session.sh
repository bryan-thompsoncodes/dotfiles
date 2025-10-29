#!/usr/bin/env bash

# Tmux session template for VA development
# Creates a session with 4 windows for different VA repos
# Each window has 2 vertical panes: left for general terminal, right with pre-populated server command

SESSION_NAME="va-dev"
BASE_DIR="$HOME/code/department-of-veterans-affairs"

# Check if session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
  # Create new session with first window (vets-website)
  tmux new-session -d -s "$SESSION_NAME" -n "vets-website" -c "$BASE_DIR/vets-website"

  # Split window vertically (left and right panes)
  tmux split-window -h -t "$SESSION_NAME:1" -c "$BASE_DIR/vets-website"

  # Pre-populate command in right pane (pane 2) without executing
  tmux send-keys -t "$SESSION_NAME:1.2" "vets-website-server"

  # Select right pane as default
  tmux select-pane -t "$SESSION_NAME:1.2"

  # Window 2: next-build
  tmux new-window -t "$SESSION_NAME:2" -n "next-build" -c "$BASE_DIR/next-build"
  tmux split-window -h -t "$SESSION_NAME:2" -c "$BASE_DIR/next-build"
  tmux send-keys -t "$SESSION_NAME:2.2" "yarn dev"
  tmux select-pane -t "$SESSION_NAME:2.2"

  # Window 3: vets-api
  tmux new-window -t "$SESSION_NAME:3" -n "vets-api" -c "$BASE_DIR/vets-api"
  tmux split-window -h -t "$SESSION_NAME:3" -c "$BASE_DIR/vets-api"
  tmux send-keys -t "$SESSION_NAME:3.2" "vets-api-server"
  tmux select-pane -t "$SESSION_NAME:3.2"

  # Window 4: component-library
  tmux new-window -t "$SESSION_NAME:4" -n "component-library" -c "$BASE_DIR/component-library"
  tmux split-window -h -t "$SESSION_NAME:4" -c "$BASE_DIR/component-library"
  tmux send-keys -t "$SESSION_NAME:4.2" "cl-storybook"
  tmux select-pane -t "$SESSION_NAME:4.2"

  # Window 5: va.gov-cms
  tmux new-window -t "$SESSION_NAME:5" -n "va.gov-cms" -c "$BASE_DIR/va.gov-cms"
  tmux send-keys -t "$SESSION_NAME:5.1" "ddev start && ddev status"

  # Select first window by default
  tmux select-window -t "$SESSION_NAME:1"
fi

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
