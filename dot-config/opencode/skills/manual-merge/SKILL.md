---
name: manual-merge
description: Manual squash-merge a branch into main locally, using its PR description as the commit message
---

# Merge - Manual Local Squash Merge

For when you need to merge a branch into main **locally** (e.g. Forgejo
repos without squash-merge UI, or manual merges for GPG-signed commits).

Fetches the PR title and description from the forge and uses them as the
commit message. Always squash-merges to keep main's history linear.

---

## Quick Reference

```
/merge                     # merge current branch into main
/merge fix/ci-triggers     # merge named branch into main
```

---

## Execution

### 1. Determine Branch

If a branch name is provided as an argument, use it. Otherwise:

```bash
branch=$(git branch --show-current)
```

**ABORT** if the branch is `main` or `master` — you cannot merge main into main.

### 2. Detect Forge

```bash
remote_url=$(git remote get-url origin 2>/dev/null)
if [[ "$remote_url" == *"github.com"* ]]; then
  forge="github"
elif [[ "$remote_url" == *"forgejo"* || "$remote_url" == *"gitea"* || "$remote_url" == *"codeberg"* || "$remote_url" == *"snowboardtechie"* ]]; then
  forge="forgejo"
else
  forge="none"
fi
```

### 3. Find PR for Branch

Look for a PR (open or merged) with the branch as the head ref.

#### GitHub

```bash
# Try open first, then closed/merged
pr_json=$(gh pr list --head "$branch" --json number,title,body --limit 1 2>/dev/null)
if [ "$pr_json" = "[]" ] || [ -z "$pr_json" ]; then
  pr_json=$(gh pr list --head "$branch" --state merged --json number,title,body --limit 1 2>/dev/null)
fi
```

#### Forgejo

`tea` output is limited, so use the Forgejo API directly:

```bash
# Extract credentials from tea config
TEA_CONFIG=""
for candidate in \
  "${XDG_CONFIG_HOME:-$HOME/.config}/tea/config.yml" \
  "$HOME/Library/Application Support/tea/config.yml" \
  "$HOME/.tea/tea.yml"; do
  [ -f "$candidate" ] && TEA_CONFIG="$candidate" && break
done

TOKEN=$(grep 'token:' "$TEA_CONFIG" | head -1 | awk '{print $2}')
remote_url=$(git remote get-url origin)
owner_repo=$(echo "$remote_url" | sed -E 's|.*[:/]([^/]+/[^/]+?)(\.git)?$|\1|')
instance=$(echo "$remote_url" | sed -E 's|.*(@|//)([^:/]+).*|https://\2|')

# Search open PRs first, then closed
pr_json=$(curl -s "${instance}/api/v1/repos/${owner_repo}/pulls?state=open&head=${branch}" \
  -H "Authorization: token $TOKEN")

# If empty array, try closed
if [ "$pr_json" = "[]" ]; then
  pr_json=$(curl -s "${instance}/api/v1/repos/${owner_repo}/pulls?state=closed&head=${branch}" \
    -H "Authorization: token $TOKEN")
fi
```

Parse the first result to extract `title` and `body`.

### 4. Handle Missing PR

If no PR is found:

```
No PR found for branch "$branch".

Options:
1. Provide a commit message manually
2. Abort and create a PR first

What would you like to do?
```

If the user provides a manual message, use it. Otherwise abort.

### 5. Confirm with User

Show what will happen:

```
Squash-merging "$branch" into main:

  Title: <PR title>
  PR #<number>

  <first 5 lines of PR body>

Proceed? (This will switch to main and squash-merge)
```

### 6. Pre-flight Checks

Before merging, verify:

```bash
# Working tree is clean
git status --porcelain
# If dirty, ABORT: "Working tree has uncommitted changes. Commit or stash first."

# Main is up to date with remote
git fetch origin main
git log main..origin/main --oneline
# If behind, warn: "main is behind origin/main. Pull first?"
```

### 7. Squash Merge

```bash
git checkout main
git merge --squash "$branch"
```

If there are merge conflicts, report them and abort:
```bash
git merge --abort
git checkout "$branch"
# Report conflicts to user
```

### 8. Commit

Use the PR title as the commit subject and the PR body as the commit body.

Format the commit message as:

```
<PR title> (#<PR number>)

<PR body>
```

Example:
```
fix: allow manual CI triggers, apply rustfmt, fix clippy warnings (#2)

## Summary

Fix CI pipeline configuration and repo discovery filtering.

## Changes

- Add `manual` to Woodpecker CI event filter...
```

```bash
git commit -m "<PR title> (#<PR number>)" -m "<PR body>"
```

**Note:** If the PR body is very long, it's fine to include it all — git
handles long commit messages gracefully.

### 9. Report

```
Squash-merged "$branch" into main as commit <short-sha>.

Next steps:
- Review: git log -1
- Push: git push origin main
- Force push (if rewriting): git push --force-with-lease origin main
- Clean up branch: git branch -D $branch && git push origin --delete $branch
```

**DO NOT push automatically.** Let the user decide when and how to push.

---

## Hard Rules

| Rule | Rationale |
|------|-----------|
| ALWAYS `--squash` | Clean linear history on main |
| NEVER regular merge into main | No merge commits cluttering history |
| NEVER push automatically | User controls what goes to remote |
| ALWAYS look for PR first | PR descriptions are the source of truth |
| ABORT on conflicts | Don't try to resolve automatically |
| ABORT on dirty worktree | Prevent accidental data loss |

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| Already on main | Error: "Switch to the feature branch first, or pass branch name" |
| Branch doesn't exist | Error: "Branch '$branch' not found" |
| No remote | Skip PR lookup, ask for manual commit message |
| Multiple PRs for branch | Use the most recent one |
| PR is still open | Proceed anyway (local merge doesn't close remote PR) |
| Branch has no commits ahead of main | Warn: "Nothing to merge — branch is up to date with main" |
