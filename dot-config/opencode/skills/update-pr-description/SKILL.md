---
name: update-pr-description
description: Update PR description following template instructions and including diff summary
argument-hint: <pr-number-or-url>
---

# Update PR Description

Update a pull request description by following whatever template instructions exist in the PR body and including a summary of changes from the diff. Supports both GitHub and Forgejo forges.

---

## Input

Accepts either:

- PR number: `update-pr-description 42170`
- PR URL: `update-pr-description https://github.com/org/repo/pull/42170`
- PR URL (Forgejo): `update-pr-description https://git.example.com/owner/repo/pulls/1`
- Nothing (will detect PR from current branch)

---

## Step 0: Detect Forge

Determine which forge hosts this repo:

```bash
remote_url=$(git remote get-url origin 2>/dev/null)
if [[ "$remote_url" == *"github.com"* ]]; then
  forge="github"
elif [[ "$remote_url" == *"forgejo"* || "$remote_url" == *"gitea"* || "$remote_url" == *"snowboardtechie"* ]]; then
  forge="forgejo"
else
  forge="unknown"
fi
```

### Forgejo: Parse Remote URL

Extract the instance URL, owner, and repo from the remote:

```bash
# From HTTPS: https://git.snowboardtechie.com/bryan/fj-dash.git
# From SSH:   git@git.snowboardtechie.com:bryan/fj-dash.git
instance="https://git.snowboardtechie.com"  # scheme + host from remote
owner="bryan"
repo="fj-dash"   # strip .git suffix
```

Or from a Forgejo PR URL like `https://git.example.com/owner/repo/pulls/1`:
- instance = `https://git.example.com`
- owner = path segment 1
- repo = path segment 2
- PR index = path segment 4

---

## Step 1: Identify the PR

### If PR number/URL provided:

Parse the input to extract the PR number and repo (if URL provided).

### If no argument provided:

**GitHub:**

```bash
BRANCH=$(git branch --show-current)
gh pr list --head "$BRANCH" --json number,title,url,body --limit 1
```

**Forgejo:**

```bash
BRANCH=$(git branch --show-current)
tea api "/repos/${owner}/${repo}/pulls?state=open" \
  | jq -c --arg branch "$BRANCH" '.[] | select(.head.ref == $branch) | {number: .number, title: .title, url: .html_url, body: .body}' \
  | head -1
```

---

## Step 2: Fetch PR Details and Diff

**GitHub:**

```bash
gh pr view {number} \
  --repo {org}/{repo} \
  --json number,title,url,body,baseRefName

git diff {baseRefName}...HEAD --stat
git diff {baseRefName}...HEAD
```

**Forgejo:**

```bash
# Get PR metadata including current description
tea api "/repos/${owner}/${repo}/pulls/{index}" \
  | jq '{number: .number, title: .title, url: .html_url, body: .body, baseRefName: .base.ref}'

# Get the diff (same git commands for both forges)
git diff {baseRefName}...HEAD --stat
git diff {baseRefName}...HEAD
```

---

## Step 3: Read the Template

The PR body contains the repository's template. Read it carefully:

1. **Look for instructions** at the top (often says to delete placeholder text)
2. **Identify sections** (Summary, Testing, Related Issues, etc.)
3. **Find placeholders** - usually in italics, parentheses, or marked as `_(placeholder)_`
4. **Note checkboxes** - which need to be filled `[x]` or justified

**Follow whatever instructions the template provides.**

---

## Step 4: Generate Updated Description

Using the diff to understand what changed:

1. **Follow the template's own instructions** (delete what it says to delete)
2. **Fill in all sections** based on the actual changes
3. **Check relevant boxes** with `[x]` or add justifications like `_N/A - reason_`
4. **Be specific and factual** - use the diff to inform your answers
5. **Link to issues** if you find issue numbers in branch name, commits, or original body

---

## Step 5: Update the PR

**GitHub:**

```bash
gh pr edit {number} --body "$(cat <<'EOF'
{generated description}
EOF
)"
```

**Forgejo:**

```bash
# Build JSON payload with the description
body_json=$(jq -n --arg body "{generated description}" '{body: $body}')

tea api --method PATCH "/repos/${owner}/${repo}/pulls/{index}" \
  --body "$body_json"
```

If `tea api` is unavailable, fall back to `curl`:

```bash
# Get token from tea config — check platform-specific paths
TEA_CONFIG=""
for candidate in \
  "${XDG_CONFIG_HOME:-$HOME/.config}/tea/config.yml" \
  "$HOME/Library/Application Support/tea/config.yml" \
  "$HOME/.tea/tea.yml"; do
  [ -f "$candidate" ] && TEA_CONFIG="$candidate" && break
done

TOKEN=$(python3 -c "
import yaml, sys
with open('$TEA_CONFIG') as f:
    c = yaml.safe_load(f)
for l in c.get('logins', []):
    if '${instance}' in l.get('url', ''):
        print(l['token']); sys.exit()
")

curl -X PATCH "${instance}/api/v1/repos/${owner}/${repo}/pulls/{index}" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$body_json"
```

---

## Step 6: Confirm Completion

Report:

```
Updated PR #{number}: {title}
   {url}
```

---

## Error Handling

### PR not found

```
Could not find PR #{number}
   Verify the PR exists and you have access.
```

### Cannot determine current PR

```
No PR found for current branch: {branch}
   Please provide a PR number: update-pr-description <number>
```

### Forge not detected

```
Could not detect forge from remote URL: {remote_url}
   Supported forges: GitHub (github.com), Forgejo/Gitea (forgejo/gitea/snowboardtechie in URL)
```

### tea not authenticated (Forgejo)

```
tea CLI not authenticated. Run: tea login add
   Or set FORGEJO_TOKEN environment variable.
```
