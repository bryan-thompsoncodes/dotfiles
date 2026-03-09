#!/usr/bin/env bash

# Claude Max 5-hour usage monitor for tmux status bar
# Displays utilization % and reset countdown with Nightfly color thresholds
# Requires: curl, jq
# macOS: reads OAuth token from Keychain ("Claude Code-credentials")
# Linux: reads OAuth token from ~/.claude/.credentials.json
# Auto-refreshes expired OAuth tokens using the refresh token

# ── Constants ─────────────────────────────────────────────────────────────────
CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/tmux-claude-usage-cache"
CACHE_TTL=300

OAUTH_TOKEN_ENDPOINT="https://console.anthropic.com/v1/oauth/token"
OAUTH_CLIENT_ID="9d1c250a-e61b-44d9-88ed-5944d1962f5e"
REFRESH_LOCK="${XDG_RUNTIME_DIR:-/tmp}/tmux-claude-refresh.lock"

# Nightfly theme colors (hardcoded — tmux %hidden vars inaccessible from #())
COLOR_GREEN="#3EFFDC"
COLOR_YELLOW="#FFDA7B"
COLOR_RED="#FF4A4A"

# ── Prerequisites ─────────────────────────────────────────────────────────────
command -v jq >/dev/null 2>&1 || exit 0
command -v curl >/dev/null 2>&1 || exit 0

# ── Read credentials ──────────────────────────────────────────────────────────
# macOS: Keychain, Linux: credentials file
# Sets globals: CREDS_JSON, TOKEN, EXPIRES_AT
read_credentials() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CREDS_JSON=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    else
        local creds_file="$HOME/.claude/.credentials.json"
        [[ -f "$creds_file" ]] || return 1
        CREDS_JSON=$(cat "$creds_file" 2>/dev/null)
    fi
    [[ -n "$CREDS_JSON" ]] || return 1

    TOKEN=$(printf '%s' "$CREDS_JSON" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    [[ -n "$TOKEN" ]] || return 1

    EXPIRES_AT=$(printf '%s' "$CREDS_JSON" | jq -r '.claudeAiOauth.expiresAt // empty' 2>/dev/null)
    return 0
}

# ── OAuth token refresh ──────────────────────────────────────────────────────
# Uses refresh_token grant to obtain new access + refresh tokens.
# Token rotation: old refresh token is revoked on use — must save the new one.
refresh_oauth_token() {
    local refresh_token
    refresh_token=$(printf '%s' "$CREDS_JSON" | jq -r '.claudeAiOauth.refreshToken // empty' 2>/dev/null)
    [[ -n "$refresh_token" ]] || return 1

    # Lock: prevent concurrent refreshes (token rotation = only one caller wins)
    # Stale lock removal: if lock is older than 30s, previous holder likely crashed
    if [[ -d "$REFRESH_LOCK" ]]; then
        local lock_mtime
        lock_mtime=$(stat -c %Y "$REFRESH_LOCK" 2>/dev/null || stat -f %m "$REFRESH_LOCK" 2>/dev/null)
        [[ $(( $(date +%s) - ${lock_mtime:-0} )) -gt 30 ]] && rmdir "$REFRESH_LOCK" 2>/dev/null
    fi
    if ! mkdir "$REFRESH_LOCK" 2>/dev/null; then
        # Another process is refreshing — wait, then re-read their result
        sleep 2
        read_credentials
        return $?
    fi

    local response error new_access new_refresh expires_in
    response=$(curl -s --max-time 10 --connect-timeout 5 -X POST \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -d "grant_type=refresh_token&refresh_token=${refresh_token}&client_id=${OAUTH_CLIENT_ID}" \
        "$OAUTH_TOKEN_ENDPOINT" 2>/dev/null)

    error=$(printf '%s' "$response" | jq -r '.error // empty' 2>/dev/null)
    if [[ -n "$error" ]]; then
        rmdir "$REFRESH_LOCK" 2>/dev/null
        return 1
    fi

    new_access=$(printf '%s' "$response" | jq -r '.access_token // empty' 2>/dev/null)
    new_refresh=$(printf '%s' "$response" | jq -r '.refresh_token // empty' 2>/dev/null)
    expires_in=$(printf '%s' "$response" | jq -r '.expires_in // empty' 2>/dev/null)
    if [[ -z "$new_access" || -z "$new_refresh" || -z "$expires_in" ]]; then
        rmdir "$REFRESH_LOCK" 2>/dev/null
        return 1
    fi

    # Build updated credentials — compact JSON required (newlines cause Keychain hex-encoding)
    local expires_at_ms new_creds
    expires_at_ms=$(( ($(date +%s) + expires_in) * 1000 ))
    new_creds=$(printf '%s' "$CREDS_JSON" | jq -c \
        --arg at "$new_access" \
        --arg rt "$new_refresh" \
        --argjson ea "$expires_at_ms" \
        '.claudeAiOauth.accessToken = $at | .claudeAiOauth.refreshToken = $rt | .claudeAiOauth.expiresAt = $ea')

    # Write back to credential store
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local acct
        acct=$(security find-generic-password -s "Claude Code-credentials" 2>/dev/null \
            | grep '"acct"' | sed 's/.*"acct"<blob>="//' | sed 's/"//')
        security delete-generic-password -s "Claude Code-credentials" >/dev/null 2>&1
        security add-generic-password -s "Claude Code-credentials" -a "${acct:-$USER}" -w "$new_creds" 2>/dev/null
    else
        printf '%s' "$new_creds" > "$HOME/.claude/.credentials.json.tmp" \
            && mv "$HOME/.claude/.credentials.json.tmp" "$HOME/.claude/.credentials.json"
    fi

    TOKEN="$new_access"
    EXPIRES_AT="$expires_at_ms"
    CREDS_JSON="$new_creds"

    rmdir "$REFRESH_LOCK" 2>/dev/null
    return 0
}

# ── Load and validate credentials ─────────────────────────────────────────────
read_credentials || exit 0

# Refresh if expired or expiring within 5 minutes
NOW_MS=$(( $(date +%s) * 1000 ))
if [[ -n "$EXPIRES_AT" && "$NOW_MS" -gt $(( EXPIRES_AT - 300000 )) ]]; then
    refresh_oauth_token || exit 0
fi

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
        # Serve stale cache if API failed
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
