#!/usr/bin/env bash
# Integration tests for scripts/reconcile-hindsight.sh.
# All writes are isolated inside temporary HOME directories, removed on exit.
# --apply's installer step is not exercised here (network); rendering,
# precondition, and check reporting are.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECONCILER="$REPO_ROOT/scripts/reconcile-hindsight.sh"

TESTS=0
FAILURES=0
TMP_HOMES=()

cleanup() {
    local h
    for h in "${TMP_HOMES[@]}"; do
        rm -rf "$h"
    done
}
trap cleanup EXIT

new_home() {
    local h
    h="$(mktemp -d "${TMPDIR:-/tmp}/hindsight-test-home-XXXXXX")"
    TMP_HOMES+=("$h")
    echo "$h"
}

check() { # <description> <expected-substring> <output>
    TESTS=$((TESTS + 1))
    local desc="$1" want="$2" got="$3"
    if [[ "$got" == *"$want"* ]]; then
        echo "ok: $desc"
    else
        echo "FAIL: $desc"
        echo "  wanted substring: $want"
        echo "  got: $got"
        FAILURES=$((FAILURES + 1))
    fi
}

# 1. Missing bearer fails loudly and mutates nothing.
H="$(new_home)"
out="$(HOME="$H" "$RECONCILER" --check 2>&1 || true)"
check "missing bearer is an error" "bearer missing" "$out"
[[ -e "$H/.hindsight" ]] && { echo "FAIL: check created ~/.hindsight"; FAILURES=$((FAILURES + 1)); }

# 2. Wrong bearer mode fails.
H="$(new_home)"
mkdir -p "$H/.secrets/hindsight"
echo fake-token > "$H/.secrets/hindsight/api-bearer"
chmod 644 "$H/.secrets/hindsight/api-bearer"
out="$(HOME="$H" "$RECONCILER" --check 2>&1 || true)"
check "world-readable bearer is an error" "must be mode 0600" "$out"

# 3. --check reports pending render without writing.
H="$(new_home)"
mkdir -p "$H/.secrets/hindsight"
echo fake-token > "$H/.secrets/hindsight/api-bearer"
chmod 600 "$H/.secrets/hindsight/api-bearer"
out="$(HOME="$H" "$RECONCILER" --check 2>&1 || true)"
check "check reports pending render" "would render" "$out"
[[ -f "$H/.hindsight/coding-agent.json" ]] && { echo "FAIL: check wrote config"; FAILURES=$((FAILURES + 1)); }

# 4. Rendered config (via the same python path the reconciler uses) carries
#    the token, expands HOME, and stays valid JSON.
rendered="$(python3 - "$REPO_ROOT/hindsight/coding-agent.template.json" <<PYEOF
import json, sys
text = open(sys.argv[1], encoding="utf-8").read()
text = text.replace("{{API_TOKEN}}", "fake-token").replace("{{HOME}}", "/Users/testuser")
cfg = json.loads(text)
assert cfg["apiToken"] == "fake-token"
assert "/Users/testuser/second-brain" in cfg["mapPathToBank"]
assert cfg["mapPathToBank"]["/Users/testuser/second-brain"] == "bryan-general"
assert cfg["pageTriggerType"] == "cron"
print("render-ok")
PYEOF
)"
check "template renders token, HOME and bryan-general routing" "render-ok" "$rendered"

echo
echo "$TESTS tests, $FAILURES failures"
exit "$((FAILURES > 0 ? 1 : 0))"
