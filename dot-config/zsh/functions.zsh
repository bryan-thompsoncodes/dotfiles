# Custom shell functions

# VA Server Scripts

function cl-storybook {
  local base_dir="$VA_CODE_DIR/component-library/packages"

  # Check if component-library exists
  if [ ! -d "$VA_CODE_DIR/component-library" ]; then
    echo "Error: component-library repository not found at $VA_CODE_DIR/component-library"
    return 1
  fi

  # Build web-components
  cd "$base_dir/web-components/" || return 1
  echo "Building web-components..."
  yarn install || return 1
  yarn build || return 1
  yarn build-bindings || return 1

  # Build react-components
  cd ../react-components/ || return 1
  echo "Building react-components..."
  yarn install || return 1
  yarn build || return 1

  # Build core
  cd ../core/ || return 1
  echo "Building core..."
  yarn install || return 1
  yarn build || return 1

  # Start storybook
  cd ../storybook/ || return 1
  echo "Starting storybook..."
  yarn install || return 1
  yarn storybook
}

function vets-api-server {
  # Check if vets-api exists
  if [ ! -d "$VA_CODE_DIR/vets-api" ]; then
    echo "Error: vets-api repository not found at $VA_CODE_DIR/vets-api"
    return 1
  fi

  cd "$VA_CODE_DIR/vets-api" || return 1

  # Start Redis in the background if not already running
  if ! redis-server --daemonize yes 2>/dev/null; then
    echo "Warning: Could not start Redis (it may already be running)"
  fi

  # Start foreman
  foreman start -m all=1,clamd=0,freshclam=0
}

function vets-website-server {
  local env=${1:-static-pages,facilities}

  # Check if vets-website exists
  if [ ! -d "$VA_CODE_DIR/vets-website" ]; then
    echo "Error: vets-website repository not found at $VA_CODE_DIR/vets-website"
    return 1
  fi

  cd "$VA_CODE_DIR/vets-website" || return 1
  yarn watch --env="$env" --watch-options-aggregate-timeout 600
}

function ddev-smart-start {
  # Check if ddev containers are actually running, start only if needed
  # Check docker ps directly for running ddev web containers (most reliable method)
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qE '^ddev-.*-web$'; then
    ddev status
  else
    ddev start && ddev status
  fi
}

# Git rebase function
# Defaults to 3 commits back, otherwise use argument passed as:
# - Count if integer: interactive rebase last N commits
# - Commit hash or branch name if string: rebase onto that ref
# Example usage:
#   grb           # interactive rebase last 3 commits
#   grb 6         # interactive rebase last 6 commits
#   grb feature   # rebase onto branch 'feature'
#   grb abc1234   # rebase onto commit abc1234
function grb {
  local commits=${1:-3}
  if [[ $commits =~ ^[0-9]+$ ]]; then
    git rebase -i HEAD~$commits
  else
    git rebase $commits
  fi
}

# Worktrunk: create worktree and add agent tmux window to current session
# Usage: wcode <branch-name> [prompt for opencode]
# Creates a worktree via wt switch -c, then adds a new tmux window
# to the current session running opencode in that worktree directory.
function wcode {
  local branch="$1"
  if [[ -z "$branch" ]]; then
    echo "Usage: wcode <branch-name> [prompt]"
    return 1
  fi
  shift
  local prompt="$*"

  # Must be inside a git repo
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "Error: not in a git repository"
    return 1
  fi

  # Must be inside tmux
  if [[ -z "$TMUX" ]]; then
    echo "Error: wcode requires an active tmux session"
    return 1
  fi

  # Create worktree in subshell; skip hooks since wcode manages tmux itself
  # and direnv auto-loads when the new shell starts in the worktree directory
  (wt switch --create --no-verify "$branch")
  local wt_exit=$?
  if [[ $wt_exit -ne 0 ]]; then
    echo "Error: failed to create worktree for branch: $branch"
    return 1
  fi

  # Get the worktree path from wt list
  local worktree_path
  worktree_path=$(wt list --format=json | jq -r ".[] | select(.branch == \"$branch\") | .path")

  if [[ -z "$worktree_path" || "$worktree_path" == "null" ]]; then
    echo "Error: could not find worktree path for branch: $branch"
    return 1
  fi

  # Add a new tmux window to the current session at the worktree path
  local sanitized_branch="${branch//\//-}"
  tmux new-window -n "$sanitized_branch" -c "$worktree_path"

  # Launch opencode in the new window
  if [[ -n "$prompt" ]]; then
    tmux send-keys -t ":$sanitized_branch" "opencode" C-m
    # Brief pause to let opencode initialize, then send the prompt
    sleep 2
    tmux send-keys -t ":$sanitized_branch" "$prompt" C-m
  else
    tmux send-keys -t ":$sanitized_branch" "opencode" C-m
  fi

  echo "Worktree '$branch' created at $worktree_path"
  echo "Tmux window '$sanitized_branch' added with opencode"
}

# Code function: opens editor in specified project directory or current directory
function code {
  local target_dir

  if [[ -n $1 && $1 != "." ]]; then
    local dir="$HOME/code/$1"
    local va_dir="$HOME/code/department-of-veterans-affairs/$1"

    if [[ -d $dir ]]; then
      target_dir="$dir"
    elif [[ -d $va_dir ]]; then
      target_dir="$va_dir"
    else
      echo "Directory $1 not found in ~/code or ~/code/department-of-veterans-affairs"
      return 1
    fi
  else
    target_dir="$PWD"
  fi

  cd "$target_dir" || return 1

  local session_script="$HOME/.tmux/opencode-editor.sh"
  if [[ ! -x $session_script ]]; then
    echo "Session script $session_script not found or not executable"
    return 1
  fi

  "$session_script"
}
