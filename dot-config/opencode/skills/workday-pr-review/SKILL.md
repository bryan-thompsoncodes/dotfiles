---
name: workday-pr-review
description: Create preliminary PR review note - fetch diff, analyze, write to Obsidian
argument-hint: <pr-number>
---

# PR Review Workflow

Create a preliminary review for a specific pull request.

## Configuration

```
VAULT_PATH="$HOME/notes/workday"
GITHUB_ORG="department-of-veterans-affairs"
PRIMARY_REPO="vets-website"
```

---

## Input

Expects a PR number, e.g., `pr review 12345` or just `12345`

---

## Step 1: Fetch PR Details

```bash
gh pr view {number} \
  --repo department-of-veterans-affairs/vets-website \
  --json number,title,author,body,files,additions,deletions,commits,url,labels
```

---

## Step 2: Fetch PR Diff

```bash
gh pr diff {number} --repo department-of-veterans-affairs/vets-website
```

---

## Step 3: Analyze Changes

Review the diff for:

### Code Quality
- Code style consistency with codebase
- Logic errors or potential bugs
- DRY violations, code duplication

### Testing
- Are changes tested?
- Test coverage adequate?
- Edge cases considered?

### Accessibility
- ARIA attributes where needed
- Keyboard navigation
- Screen reader compatibility

### Performance
- N+1 queries
- Unnecessary re-renders
- Large bundle impact

### Security
- Input validation
- XSS vulnerabilities
- Sensitive data exposure

---

## Step 4: Create Review Note

Write to `Agent 🤖/PR Reviews/PR-{number}-{short-title}.md`:

```markdown
---
date: {YYYY-MM-DD}
pr: {number}
url: {url}
author: {author}
title: {title}
status: Open
ci: passing/failing/pending
reviewed: {date}
tags:
  - pr-review
  - muse
---

# PR #{number}: {title}

## Summary

{1-2 sentence summary of what this PR does}

## Scope

- **Files changed:** N
- **Lines:** +X / -Y
- **Key areas:** {list affected components/modules}

## Files Changed

| File | Changes | Description |
|------|---------|-------------|
| path/to/file.js | +X/-Y | Brief description |

## Review Findings

### Positive

1. {Good things about this PR}

### Concerns

1. {Potential issues or risks}

### Suggestions

1. {Improvements to consider}

## Questions for Bryan

1. {Things requiring human judgment}
2. {Context questions}

## Recommendation

> [!tip] **{APPROVE / REQUEST CHANGES / NEEDS DISCUSSION}**
> {Brief rationale for the recommendation}

{More detailed explanation if needed}
```

---

## Step 5: Confirm Completion

Report:
- Review note created at `Agent 🤖/PR Reviews/PR-{number}-{short-title}.md`
- Summary of findings
- Recommendation
