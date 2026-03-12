#!/usr/bin/env bash

# Claude Max 5-hour usage monitor for tmux status bar
# Displays utilization % and reset countdown with Nightfly color thresholds
# Requires: curl, jq
# macOS: reads OAuth token from Keychain ("Claude Code-credentials")
# Linux: reads OAuth token from ~/.claude/.credentials.json
#
# NOTE: This script is read-only — it never refreshes or writes tokens.
# Claude Code owns the OAuth lifecycle. Refreshing here would race with
# Claude Code's single-use token rotation and invalidate its credentials.

# ── Constants ─────────────────────────────────────────────────────────────────
CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/tmux-claude-usage-cache"
CACHE_TTL=300

# Nightfly theme colors (hardcoded — tmux %hidden vars inaccessible from #())
COLOR_GREEN="#3EFFDC"
COLOR_YELLOW="#FFDA7B"
COLOR_RED="#FF4A4A"

# ── Prerequisites ─────────────────────────────────────────────────────────────
command -v jq >/dev/null 2>&1 || exit 0
command -v curl >/dev/null 2>&1 || exit 0

# ── Read credentials ──────────────────────────────────────────────────────────
# macOS: Keychain, Linux: credentials file
if [[ "$OSTYPE" == "darwin"* ]]; then
    CREDS_JSON=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
else
    CREDS_FILE="$HOME/.claude/.credentials.json"
    [[ -f "$CREDS_FILE" ]] || exit 0
    CREDS_JSON=$(cat "$CREDS_FILE" 2>/dev/null)
fi
[[ -n "$CREDS_JSON" ]] || exit 0

TOKEN=$(printf '%s' "$CREDS_JSON" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
[[ -n "$TOKEN" ]] || exit 0

# ── Cache: stores raw values, refreshes via API every CACHE_TTL seconds ───────
cache_age() {
    local mtime
    # macOS: stat -f %m, Linux: stat -c %Y
    mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
    echo $(( $(date +%s) - ${mtime:-0} ))
}

if [[ -f "$CACHE_FILE" ]] && [[ $(cache_age) -lt $CACHE_TTL ]]; then
    # Read cached raw values — countdown is computed fresh below
    UTILIZATION=$(sed -n '1p' "$CACHE_FILE")
    RESET_EPOCH=$(sed -n '2p' "$CACHE_FILE")
else
    # ── API probe ─────────────────────────────────────────────────────────────
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

    UTILIZATION=$(printf '%s' "$HEADERS" | grep -i 'anthropic-ratelimit-unified-5h-utilization' | sed 's/.*: *//' | grep -oE '[0-9]+\.?[0-9]*' | head -1)
    RESET_EPOCH=$(printf '%s' "$HEADERS" | grep -i 'anthropic-ratelimit-unified-5h-reset' | sed 's/.*: *//' | grep -oE '[0-9]+' | head -1)

    if [[ -z "$UTILIZATION" || -z "$RESET_EPOCH" ]]; then
        # Serve stale cache if API failed (expired token, network issue, etc.)
        if [[ -f "$CACHE_FILE" ]]; then
            UTILIZATION=$(sed -n '1p' "$CACHE_FILE")
            RESET_EPOCH=$(sed -n '2p' "$CACHE_FILE")
        else
            exit 0
        fi
    else
        printf '%s\n%s\n' "$UTILIZATION" "$RESET_EPOCH" > "${CACHE_FILE}.tmp" \
            && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
    fi
fi

[[ -n "$UTILIZATION" && -n "$RESET_EPOCH" ]] || exit 0

# ── Compute display (fresh every render) ──────────────────────────────────────
PCT=$(awk "BEGIN {printf \"%.0f\", $UTILIZATION * 100}" 2>/dev/null)

NOW=$(date +%s)
REMAINING=$(( RESET_EPOCH - NOW ))
[[ $REMAINING -lt 0 ]] && REMAINING=0
HOURS=$(( REMAINING / 3600 ))
MINS=$(printf "%02d" $(( (REMAINING % 3600) / 60 )))

if [[ $PCT -ge 90 ]]; then
    COLOR="$COLOR_RED"
elif [[ $PCT -ge 70 ]]; then
    COLOR="$COLOR_YELLOW"
else
    COLOR="$COLOR_GREEN"
fi

# Trailing " | " separator — script owns its separator so status bar looks clean
# when script outputs nothing (no orphaned pipes)
printf '#[fg=%s]✨ %s%% ↻ %s:%s#[fg=default] | ' "$COLOR" "$PCT" "$HOURS" "$MINS"
