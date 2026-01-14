#!/usr/bin/env bash

# Tmux session template for VA development
# Creates a session with 4 windows for different VA repos
# Each window has 2 horizontal panes: top for general terminal, bottom with pre-populated server command

# Ensure we have a proper TTY for tmux
if [[ ! -t 0 ]]; then
  exec </dev/tty
fi

SESSION_NAME="va-dev"
# Use VA_CODE_DIR environment variable if set, otherwise use default
BASE_DIR="${VA_CODE_DIR:-$HOME/code/department-of-veterans-affairs}"

# Required repositories for this session
REQUIRED_REPOS=("vets-website" "next-build" "vets-api" "component-library" "va.gov-cms")

# Validate all required repositories exist
MISSING_REPOS=()
for repo in "${REQUIRED_REPOS[@]}"; do
  if [ ! -d "$BASE_DIR/$repo" ]; then
    MISSING_REPOS+=("$repo")
  fi
done

# If any repos are missing, show error and exit
if [ ${#MISSING_REPOS[@]} -gt 0 ]; then
  echo "Error: The following required repositories are missing:"
  for repo in "${MISSING_REPOS[@]}"; do
    echo "  - $BASE_DIR/$repo"
  done
  echo ""
  echo "Please run 'setup-va-repos.sh' or manually clone the missing repositories."
  exit 1
fi

# Check if session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
  # Create new session with first window (vets-website)
  tmux new-session -d -s "$SESSION_NAME" -n "vets-website" -c "$BASE_DIR/vets-website"

  # Split window horizontally (top and bottom panes)
  tmux split-window -v -t "$SESSION_NAME:1" -c "$BASE_DIR/vets-website"

  # Pre-populate command in bottom pane (pane 2) without executing
  tmux send-keys -t "$SESSION_NAME:1.2" "vets-website-server"

  # Select bottom pane as default
  tmux select-pane -t "$SESSION_NAME:1.2"

  # Window 2: next-build
  tmux new-window -t "$SESSION_NAME:2" -n "next-build" -c "$BASE_DIR/next-build"
  tmux split-window -v -t "$SESSION_NAME:2" -c "$BASE_DIR/next-build"
  tmux send-keys -t "$SESSION_NAME:2.2" "yarn dev"
  tmux select-pane -t "$SESSION_NAME:2.2"

  # Window 3: vets-api
  tmux new-window -t "$SESSION_NAME:3" -n "vets-api" -c "$BASE_DIR/vets-api"
  tmux split-window -v -t "$SESSION_NAME:3" -c "$BASE_DIR/vets-api"
  tmux send-keys -t "$SESSION_NAME:3.2" "vets-api-server"
  tmux select-pane -t "$SESSION_NAME:3.2"

  # Window 4: component-library
  tmux new-window -t "$SESSION_NAME:4" -n "component-library" -c "$BASE_DIR/component-library"
  tmux split-window -v -t "$SESSION_NAME:4" -c "$BASE_DIR/component-library"
  tmux send-keys -t "$SESSION_NAME:4.2" "cl-storybook"
  tmux select-pane -t "$SESSION_NAME:4.2"

  # Window 5: va.gov-cms
  tmux new-window -t "$SESSION_NAME:5" -n "va.gov-cms" -c "$BASE_DIR/va.gov-cms"
  tmux send-keys -t "$SESSION_NAME:5.1" "ddev-smart-start"

  # Select first window by default
  tmux select-window -t "$SESSION_NAME:1"
fi

# Attach to the session (or switch if already in tmux)
if [[ -n "$TMUX" ]]; then
  tmux switch-client -t "$SESSION_NAME"
else
  tmux attach-session -t "$SESSION_NAME"
fi
