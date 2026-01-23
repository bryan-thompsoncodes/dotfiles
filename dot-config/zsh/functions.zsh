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

# Code function: opens editor in specified project directory or current directory
function code {
  local target_dir session_script

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

  if [[ "$target_dir" == "$HOME/code/department-of-veterans-affairs"* || "$target_dir" == "$HOME/code/va_dev"* ]]; then
    session_script="$HOME/.tmux/va-dev-editor.sh"
  else
    session_script="$HOME/.tmux/opencode-editor.sh"
  fi

  if [[ ! -x $session_script ]]; then
    echo "Session script $session_script not found or not executable"
    return 1
  fi

  "$session_script"
}
