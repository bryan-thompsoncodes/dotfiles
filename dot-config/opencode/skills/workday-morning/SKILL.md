---
name: workday-morning
description: Morning sync workflow - daily note, sprint board, PRs, review queue, priorities
---

# Morning Sync Workflow

Full morning workflow to start Bryan's workday.

## Configuration

```
VAULT_PATH="$HOME/notes/workday"
GITHUB_USER="bryan-thompsoncodes"
GITHUB_ORG="department-of-veterans-affairs"
PRIMARY_REPO="vets-website"
```

---

## Step 1: Locate/Create Daily Note

Determine today's daily note path:

```bash
DAY=$(date +%d)
MONTH_ABBREV=$(date +%b)
YEAR=$(date +%Y)
FILENAME="${DAY}${MONTH_ABBREV}${YEAR}.md"
VAULT_PATH="$HOME/notes/workday"
NOTE_PATH="${VAULT_PATH}/daily/${FILENAME}"

ls "$NOTE_PATH" 2>/dev/null || echo "CREATE_NEEDED"
```

If daily note doesn't exist, create with template containing:
- Current Sprint section with board link
- Due Today / This Week / Awaiting Response sections
- Agent Updates section
- End of Day section
- For Agent section

---

## Step 2: Check Yesterday's Tasks

Read yesterday's daily note. Look for uncompleted items in "For Agent" section. Carry forward if still relevant.

---

## Step 3: Sprint Board Check

```bash
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

---

## Step 4: PR Status Check (Your PRs)

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

---

## Step 5: Review Queue Check

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
   - Would go in `Agent 🤖/PR Reviews/PR-{number}-{short-title}.md`
3. For PRs that should be skipped, note WHY:
   - `WIP, CI failing`
   - `Draft, stale`
   - `2+ months old`

---

## Step 6: Check WIP Projects

Read notes in `Projects/WIP/` for active work context.
Read notes in `Agent 🤖/Working/` for in-progress collaboration state.

---

## Step 7: Update Daily Note

Write to "Agent Updates" section with format:

```markdown
## Agent Updates
*Morning sync: {date} @ {time} PT*

### Sprint Board (Sprint N: dates)

| Status | Count | Tickets |
|--------|-------|---------|
| Blocked | N | #xxx, #yyy |
| Sprint Commitment | N | #xxx |
| In Progress | N | [[Project|#xxx]], #yyy |

### Your PRs (N open)

| PR | Title | Status |
|----|-------|--------|
| #xxx | Title | Approved / Failing CI / Pending review |

### Review Queue (N pending)

| PR | Title | Author | Age | Status |
|----|-------|--------|-----|--------|
| #xxx | Title | Author | Xd | Needs review / Skipped: reason |

### WIP Projects

**[[Project Name]]** - status summary

### Suggested Priorities

1. First priority with reasoning
2. Second priority
3. Third priority
```

Use Obsidian wikilinks: `[[Note Name]]` or `[[Note Name|display text]]`
