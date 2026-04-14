#!/usr/bin/env bash
# Bridge for worktrunk LLM commit generation via opencode
# Worktrunk pipes the prompt to stdin; opencode takes it as a positional arg
# Uses --agent commit-msg for a minimal system prompt (no Sisyphus overhead)
prompt=$(cat)
output=$(opencode run --agent commit-msg --format json "$prompt" 2>/dev/null)
if [[ $? -ne 0 || -z "$output" ]]; then
  echo "Error: commit message generation failed" >&2
  exit 1
fi
echo "$output" | jq -sr '[.[] | select(.type == "text")] | map(.part.text) | join("")'
