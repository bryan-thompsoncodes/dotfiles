#!/usr/bin/env bash

# Claude service status monitor for tmux status bar.
# Polls status.claude.com (Anthropic's Statuspage) and shows a colored
# warning with the active incident name when the service is degraded.
# Silent when everything is operational.
# Requires: curl, jq
#
# Click-through: tmux status bars don't reliably pass OSC 8 hyperlinks,
# so dot-tmux.conf binds `prefix + a` to open https://status.claude.com.

# ── Constants ─────────────────────────────────────────────────────────────────
CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/tmux-claude-status-cache"
CACHE_TTL=60
STATUS_API="https://status.claude.com/api/v2/summary.json"

# Hardcoded — tmux %hidden vars are inaccessible from #() shell calls.
# Kept in sync with dot-tmux.conf NIGHTFLY_* palette.
COLOR_YELLOW="#FFDA7B"
COLOR_ORANGE="#FF9E64"
COLOR_RED="#FF4A4A"
COLOR_BLUE="#65D1FF"

# ── Prerequisites ─────────────────────────────────────────────────────────────
command -v jq >/dev/null 2>&1 || exit 0
command -v curl >/dev/null 2>&1 || exit 0

# ── Cache: stores indicator + message, refreshes every CACHE_TTL seconds ──────
cache_age() {
    local mtime
    mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
    echo $(( $(date +%s) - ${mtime:-0} ))
}

if [[ -f "$CACHE_FILE" ]] && [[ $(cache_age) -lt $CACHE_TTL ]]; then
    INDICATOR=$(sed -n '1p' "$CACHE_FILE")
    MESSAGE=$(sed -n '2p' "$CACHE_FILE")
else
    RESP=$(curl -sL \
        --max-time 4 \
        --connect-timeout 3 \
        --retry 0 \
        "$STATUS_API" 2>/dev/null)

    INDICATOR=$(printf '%s' "$RESP" | jq -r '.status.indicator // empty' 2>/dev/null)
    # Prefer the first active incident's name (e.g. "Elevated errors on Opus 4.7"),
    # which is more actionable than the generic page description.
    MESSAGE=$(printf '%s' "$RESP" | jq -r '
        (.incidents // []) | map(select(.status != "resolved" and .status != "completed")) | .[0].name
        // .status.description // empty
    ' 2>/dev/null)

    if [[ -z "$INDICATOR" ]]; then
        # Serve stale cache if API failed; otherwise stay silent.
        if [[ -f "$CACHE_FILE" ]]; then
            INDICATOR=$(sed -n '1p' "$CACHE_FILE")
            MESSAGE=$(sed -n '2p' "$CACHE_FILE")
        else
            exit 0
        fi
    else
        printf '%s\n%s\n' "$INDICATOR" "$MESSAGE" > "${CACHE_FILE}.tmp" \
            && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
    fi
fi

# Silent when all systems operational.
[[ -z "$INDICATOR" || "$INDICATOR" == "none" ]] && exit 0

# Map indicator → color + icon
case "$INDICATOR" in
    minor)       COLOR="$COLOR_YELLOW"; ICON="⚠" ;;
    major)       COLOR="$COLOR_ORANGE"; ICON="⚠" ;;
    critical)    COLOR="$COLOR_RED";    ICON="✖" ;;
    maintenance) COLOR="$COLOR_BLUE";   ICON="🛠" ;;
    *)           COLOR="$COLOR_YELLOW"; ICON="⚠" ;;
esac

# Truncate long incident names so the status bar stays readable.
MAX_LEN=48
if (( ${#MESSAGE} > MAX_LEN )); then
    MESSAGE="${MESSAGE:0:MAX_LEN}…"
fi

# Trailing " | " separator — script owns its separator so status bar looks clean
# when script outputs nothing (no orphaned pipes).
printf '#[fg=%s,bold]%s Claude: %s#[fg=default,nobold] | ' "$COLOR" "$ICON" "$MESSAGE"
