#!/usr/bin/env bash

# Claude Max 5-hour usage monitor for tmux status bar
# Displays utilization % and reset countdown with Nightfly color thresholds
# Requires: curl, jq, ~/.claude/.credentials.json with valid OAuth token

# ── Constants ─────────────────────────────────────────────────────────────────
CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/tmux-claude-usage-cache"
CACHE_TTL=300
CREDS_FILE="$HOME/.claude/.credentials.json"

# Nightfly theme colors (hardcoded — tmux %hidden vars inaccessible from #())
COLOR_GREEN="#3EFFDC"
COLOR_YELLOW="#FFDA7B"
COLOR_RED="#FF4A4A"

# ── Prerequisites ─────────────────────────────────────────────────────────────
command -v jq >/dev/null 2>&1 || exit 0
command -v curl >/dev/null 2>&1 || exit 0
[[ -f "$CREDS_FILE" ]] || exit 0

# ── Read credentials ──────────────────────────────────────────────────────────
TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE" 2>/dev/null)
[[ -n "$TOKEN" ]] || exit 0

EXPIRES_AT=$(jq -r '.claudeAiOauth.expiresAt // empty' "$CREDS_FILE" 2>/dev/null)
# expiresAt is milliseconds epoch (13 digits) — compare to current time in ms
NOW_MS=$(( $(date +%s) * 1000 ))
[[ -n "$EXPIRES_AT" && "$NOW_MS" -gt "$EXPIRES_AT" ]] && exit 0

# ── Cache check ───────────────────────────────────────────────────────────────
cache_age() {
    local mtime
    # macOS: stat -f %m, Linux: stat -c %Y
    mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
    echo $(( $(date +%s) - ${mtime:-0} ))
}

if [[ -f "$CACHE_FILE" ]] && [[ $(cache_age) -lt $CACHE_TTL ]]; then
    cat "$CACHE_FILE"
    exit 0
fi

# ── API probe ─────────────────────────────────────────────────────────────────
# Capture response headers; discard body. Redirect stderr to stdout to capture headers.
HEADERS=$(curl -s \
    --max-time 4 \
    --connect-timeout 3 \
    --retry 0 \
    -D - \
    -o /dev/null \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-version: 2023-06-01" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Content-Type: application/json" \
    -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}' \
    "https://api.anthropic.com/v1/messages" 2>/dev/null)

# ── Parse headers ─────────────────────────────────────────────────────────────
UTILIZATION=$(printf '%s' "$HEADERS" | grep -i 'anthropic-ratelimit-unified-5h-utilization' | sed 's/.*: *//' | grep -oE '[0-9]+\.?[0-9]*' | head -1)
RESET_EPOCH=$(printf '%s' "$HEADERS" | grep -i 'anthropic-ratelimit-unified-5h-reset' | sed 's/.*: *//' | grep -oE '[0-9]+' | head -1)

# If headers missing (API error, non-OAuth response), serve stale cache or exit
if [[ -z "$UTILIZATION" || -z "$RESET_EPOCH" ]]; then
    [[ -f "$CACHE_FILE" ]] && cat "$CACHE_FILE"
    exit 0
fi

# ── Calculate display values ──────────────────────────────────────────────────
# Percentage: utilization * 100, rounded to integer
PCT=$(awk "BEGIN {printf \"%.0f\", $UTILIZATION * 100}" 2>/dev/null)

# Reset countdown: seconds remaining until reset window
NOW=$(date +%s)
REMAINING=$(( RESET_EPOCH - NOW ))
[[ $REMAINING -lt 0 ]] && REMAINING=0
HOURS=$(( REMAINING / 3600 ))
MINS=$(printf "%02d" $(( (REMAINING % 3600) / 60 )))

# ── Color selection ───────────────────────────────────────────────────────────
if [[ $PCT -ge 90 ]]; then
    COLOR="$COLOR_RED"
elif [[ $PCT -ge 70 ]]; then
    COLOR="$COLOR_YELLOW"
else
    COLOR="$COLOR_GREEN"
fi

# ── Format output ─────────────────────────────────────────────────────────────
# Trailing " | " separator — script owns its separator so status bar looks clean
# when script outputs nothing (no orphaned pipes)
DISPLAY="#[fg=${COLOR}]✨ ${PCT}% ↻ ${HOURS}:${MINS}#[fg=default] | "

# ── Atomic cache write ────────────────────────────────────────────────────────
printf '%s' "$DISPLAY" > "${CACHE_FILE}.tmp" && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"

# ── Output ────────────────────────────────────────────────────────────────────
printf '%s' "$DISPLAY"
