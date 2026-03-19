---
name: ship
description: Wrap up worktree work - push branch, open PR, fill description, report URL
---

# Ship - Worktree Wrap-Up

Push the current branch, open a PR, and fill the description.

Follows the "Wrapping Up" flow from the `worktrunk` skill. Load it for full details.

---

## Quick Reference

```
/ship           # wrap up current branch — detect forge, push, open PR
```

---

## Execution

### 1. Detect Forge

```bash
remote_url=$(git remote get-url origin 2>/dev/null)
if [[ "$remote_url" == *"github.com"* ]]; then
  forge="github"
elif [[ "$remote_url" == *"forgejo"* || "$remote_url" == *"gitea"* || "$remote_url" == *"snowboardtechie"* ]]; then
  forge="forgejo"
else
  echo "No supported forge detected — use wt merge instead"
  exit 1
fi
```

### 2. Pre-flight

- `git branch --show-current` must not be `main` or `master`
- `git remote -v` returns output
- Forge CLI authenticated: `gh auth status` (GitHub) or tea config file exists with token (Forgejo)
- No existing PR: `gh pr list --head <branch>` (GitHub) or Forgejo API `GET /repos/{owner}/{repo}/pulls?state=open` (Forgejo)

If any check fails, report what's wrong and stop.

### 3. Confirm

Ask: "Ready to push and open a draft PR?"

### 4. Push

```bash
git push -u origin <branch>
```

### 5. Create PR

#### GitHub

```bash
gh pr create --fill --draft
```

**Always open as draft.** Never use `--fill` without `--draft`.

#### Forgejo

**Never use `tea pr` commands.** They require TTY interaction and will fail in agent environments. Always use the Forgejo API directly:

```bash
# 1. Extract token from tea config
TEA_CONFIG=""
for candidate in \
  "${XDG_CONFIG_HOME:-$HOME/.config}/tea/config.yml" \
  "$HOME/Library/Application Support/tea/config.yml" \
  "$HOME/.tea/tea.yml"; do
  [ -f "$candidate" ] && TEA_CONFIG="$candidate" && break
done

# 2. Parse token (requires PyYAML or grep)
TOKEN=$(grep 'token:' "$TEA_CONFIG" | head -1 | awk '{print $2}')

# 3. Parse owner/repo from remote
remote_url=$(git remote get-url origin)
# SSH: ssh://forgejo@git.example.com/owner/repo.git → owner/repo
# HTTPS: https://git.example.com/owner/repo.git → owner/repo
owner_repo=$(echo "$remote_url" | sed -E 's|.*[:/]([^/]+/[^/]+?)(\.git)?$|\1|')
instance=$(echo "$remote_url" | sed -E 's|.*(@\|//)([^:/]+).*|https://\2|')

# 4. Create PR via API
curl -s -X POST "${instance}/api/v1/repos/${owner_repo}/pulls" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"<PR title>\",\"head\":\"<branch>\",\"base\":\"main\",\"body\":\"<description>\",\"draft\":true}"
```

Extract the PR number and URL from the JSON response:
```bash
| python3 -c "import sys,json; d=json.load(sys.stdin); print(f'PR #{d[\"number\"]}: {d[\"html_url\"]}')"
```

### 6. Fill Description

Write a comprehensive PR description covering:
- Summary of changes (what and why)
- Key features/files added or modified
- Testing (test counts, what was verified)
- Commit list

Then update via the API:
```bash
# GitHub
gh pr edit {number} --body "$BODY"

# Forgejo (always use API)
body_json=$(python3 -c "import json,sys; print(json.dumps({'body': sys.stdin.read()}))" <<< "$BODY")
curl -s -X PATCH "${instance}/api/v1/repos/${owner_repo}/pulls/{number}" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$body_json"
```

### 7. Report

Show the PR URL to the user.
