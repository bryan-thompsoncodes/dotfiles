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
- Forge CLI authenticated: `gh auth status` (GitHub) or `tea login list` (Forgejo)
- No existing PR: `gh pr list --head <branch>` (GitHub) or `tea pr list --state open | grep <branch>` (Forgejo)

If any check fails, report what's wrong and stop.

### 3. Confirm

Ask: "Should I open a PR for this work? Draft or ready-for-review?"

### 4. Push + Create PR

```bash
git push -u origin <branch>
```

| Forge | Ready | Draft |
|-------|-------|-------|
| GitHub | `gh pr create --fill` | `gh pr create --fill --draft` |
| Forgejo | `tea pr create --head <branch> --base main` | `tea pr create --head <branch> --base main --draft` |

### 5. Fill Description

Invoke `/update-pr-description` to fill the PR template from the diff.

### 6. Report

Show the PR URL to the user.
