---
name: update-pr-description
description: Update GitHub PR description following template instructions and including diff summary
argument-hint: <pr-number-or-url>
---

# Update PR Description

Update a GitHub pull request description by following whatever template instructions exist in the PR body and including a summary of changes from the diff.

---

## Input

Accepts either:

- PR number: `update-pr-description 42170`
- PR URL: `update-pr-description https://github.com/org/repo/pull/42170`
- Nothing (will detect PR from current branch)

---

## Step 1: Identify the PR

### If PR number/URL provided:

Parse the input to extract the PR number and repo (if URL provided).

### If no argument provided:

```bash
# Get current branch
BRANCH=$(git branch --show-current)

# Find PR for this branch
gh pr list --head "$BRANCH" --json number,title,url,body --limit 1
```

---

## Step 2: Fetch PR Details and Diff

```bash
# Get PR metadata including current description
gh pr view {number} \
  --repo {org}/{repo} \
  --json number,title,url,body,baseRefName

# Get the diff
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

```bash
gh pr edit {number} --body "$(cat <<'EOF'
{generated description}
EOF
)"
```

---

## Step 6: Confirm Completion

Report:

```
✅ Updated PR #{number}: {title}
   {url}
```

---

## Error Handling

### PR not found

```
❌ Could not find PR #{number}
   Verify the PR exists and you have access.
```

### Cannot determine current PR

```
❌ No PR found for current branch: {branch}
   Please provide a PR number: update-pr-description <number>
```
