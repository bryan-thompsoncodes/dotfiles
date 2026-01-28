---
description: Daily workflow automation - morning sync, EOD summaries, PR reviews, sprint status
argument-hint: <trigger>
model: anthropic/claude-sonnet-4-5
allowed-tools:
  - mcp_bash
  - mcp_read
  - mcp_write
  - mcp_glob
  - mcp_grep
  - mcp_edit
---

# Workday Skill

Daily workflow automation for VA.gov development work integrated with Obsidian vault.

## Trigger Detection

Parse the user's message to identify which workflow to execute:

| User Says | Workflow |
|-----------|----------|
| `morning sync`, `start my day`, `good morning` | Morning Sync |
| `wrap up`, `end of day`, `EOD` | End of Day |
| `check my PRs` | PR Status Check |
| `review queue` | Review Queue Check |
| `sprint status` | Sprint Board Snapshot |
| `pr review <number>` | Create PR Review Note |

---

## Configuration

```
VAULT_PATH="/Users/bryan/Library/Mobile Documents/iCloud~md~obsidian/Documents/💙 Agile6"
GITHUB_USER="bryan-thompsoncodes"
GITHUB_ORG="department-of-veterans-affairs"
PRIMARY_REPO="vets-website"
SPRINT_BOARD_URL="https://github.com/orgs/department-of-veterans-affairs/projects/1865/views/8"
```

---

## Workflow: Morning Sync

### Step 1: Locate/Create Daily Note

Determine today's daily note path:
```bash
YEAR=$(date +%Y)
MONTH_NUM=$(date +%-m)
MONTH_NAME=$(date +%B)
DAY=$(date +%d)
MONTH_ABBREV=$(date +%b)
FILENAME="${DAY}${MONTH_ABBREV}${YEAR}.md"
NOTE_PATH="${VAULT_PATH}/Calendar 🗓️/${FILENAME}"
# Or with year folders: "${VAULT_PATH}/Calendar 🗓️/${YEAR}/${MONTH_NUM}. ${MONTH_NAME}/${FILENAME}"
```

If daily note doesn't exist, create with template containing:
- Current Sprint section with board link
- Due Today / This Week / Awaiting Response sections
- Claude's Updates section
- End of Day section
- For Claude section

### Step 2: Check Yesterday's Tasks

Read yesterday's daily note. Look for uncompleted items in "For Claude" section. Carry forward if still relevant.

### Step 3: Sprint Board Check

```bash
# Get sprint tickets assigned to Bryan
gh api graphql -f query='
  query {
    organization(login: "department-of-veterans-affairs") {
      projectV2(number: 1865) {
        items(first: 100) {
          nodes {
            fieldValueByName(name: "Status") {
              ... on ProjectV2ItemFieldSingleSelectValue { name }
            }
            content {
              ... on Issue {
                number
                title
                url
                assignees(first: 5) { nodes { login } }
              }
            }
          }
        }
      }
    }
  }
'
```

Categorize tickets by status:
- Blocked
- Sprint Commitment
- In Progress

### Step 4: PR Status Check (Your PRs)

```bash
gh pr list \
  --author bryan-thompsoncodes \
  --repo department-of-veterans-affairs/vets-website \
  --json number,title,url,statusCheckRollup,reviews \
  --limit 20
```

For each PR, determine:
- CI status (passing/failing/pending)
- Review status (approved, changes requested, pending)

### Step 5: Review Queue Check

```bash
gh pr list \
  --search "review-requested:bryan-thompsoncodes" \
  --repo department-of-veterans-affairs/vets-website \
  --json number,title,author,createdAt,url,statusCheckRollup,reviews \
  --limit 20
```

For each PR needing review:
1. Check if Bryan has already reviewed (skip if yes, unless dismissed)
2. For PRs that need review AND have passing CI:
   - Offer to create preliminary review note
   - Would go in `Claude/PR Reviews/PR-{number}-{short-title}.md`
3. For PRs that should be skipped, note WHY:
   - `WIP, CI failing`
   - `Draft, stale`
   - `2+ months old`

### Step 6: Check WIP Projects

Read notes in `Projects/WIP/` for active work context.
Read notes in `Claude/Working/` for in-progress collaboration state.

### Step 7: Update Daily Note

Write to "Claude's Updates" section with format:

```markdown
# Claude's Updates
*Morning sync: {date} @ {time} PT*

## Sprint Board (Sprint N: dates)

| Status | Count | Tickets |
|--------|-------|---------|
| Blocked | N | #xxx, #yyy |
| Sprint Commitment | N | #xxx |
| In Progress | N | [[Project|#xxx]], #yyy |

## Your PRs (N open)

| PR | Title | Status |
|----|-------|--------|
| #xxx | Title | Approved / Failing CI / Pending review |

## Review Queue (N pending)

| PR | Title | Author | Age | Status |
|----|-------|--------|-----|--------|
| #xxx | Title | Author | Xd | Needs review / Skipped: reason |

## WIP Projects

**[[Project Name]]** - status summary

## Suggested Priorities

1. First priority with reasoning
2. Second priority
3. Third priority
```

Use Obsidian wikilinks: `[[Project Name|display text]]`

---

## Workflow: End of Day

### Step 1: Capture Progress

- Re-check sprint board for status changes since morning
- Note completed items, moved tickets

### Step 2: Final PR Check

- Check CI status on open PRs
- Note any new reviews or comments

### Step 3: Update Daily Note

Write to "End of Day" section:

```markdown
# End of Day
*EOD sync: {date} @ {time} PT*

## What Got Done Today
- Item 1
- Item 2

## What's Still In Flight
- Item with status

## Blockers / Awaiting Response
- Blocker description

## Review Queue (remaining)
| PR | Author | Status |
|----|--------|--------|

## Tomorrow
- Priority 1
- Priority 2
```

---

## Workflow: PR Review

When creating a preliminary PR review for PR #{number}:

### Step 1: Fetch PR Details

```bash
gh pr view {number} \
  --repo department-of-veterans-affairs/vets-website \
  --json number,title,author,body,files,additions,deletions,commits,url

gh pr diff {number} --repo department-of-veterans-affairs/vets-website
```

### Step 2: Analyze Changes

Review for:
- Code style consistency with codebase
- Logic errors or potential bugs
- Test coverage (are changes tested?)
- Accessibility concerns
- Performance implications
- Security issues

### Step 3: Create Review Note

Write to `Claude/PR Reviews/PR-{number}-{short-title}.md`:

```markdown
---
pr: {number}
url: {url}
author: {author}
title: {title}
status: Open
ci: {passing/failing/pending}
reviewed: {date}
---

# PR #{number}: {title}

## Summary

{1-2 sentence summary}

## Scope

- Files changed: N
- Lines: +X/-Y
- Key areas: ...

## Files Changed Overview

| File | Changes | Description |
|------|---------|-------------|

## Code Review Findings

### Positive
1. ...

### Concerns
1. ...

### Suggestions
1. ...

## Questions for Bryan

1. Questions needing human judgment

## Recommendation

**{APPROVE / REQUEST CHANGES / NEEDS DISCUSSION}**

{Brief reasoning}
```

---

## Quick Commands

### "check my PRs"
Run Step 4 from Morning Sync only - report PR statuses.

### "review queue"
Run Step 5 from Morning Sync only - report PRs awaiting review.

### "sprint status"
Run Step 3 from Morning Sync only - report sprint board status.

---

## Error Handling

### GitHub API Failures
If `gh` commands fail:
1. Check authentication: `gh auth status`
2. Report specific error to user
3. Continue with available data

### Missing Daily Note
If vault path is inaccessible:
1. Report the issue
2. Output sync data to chat instead

### Rate Limiting
If GitHub rate limited:
1. Report remaining quota
2. Suggest waiting or proceeding with cached data
