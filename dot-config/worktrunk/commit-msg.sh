#!/usr/bin/env bash
# Bridge for worktrunk LLM commit generation via opencode
# Worktrunk pipes the prompt to stdin; opencode takes it as a positional arg
# Uses --agent commit-msg for a minimal system prompt (no Sisyphus overhead)
prompt=$(cat)
opencode run --agent commit-msg -m anthropic/claude-haiku-4-5 --format json "$prompt" 2>/dev/null \
  | jq -sr '[.[] | select(.type == "text")] | map(.part.text) | join("")'
