---
name: workday-eod
description: End of day workflow - capture progress, final PR check, tomorrow's priorities
---

# End of Day Workflow

Wrap up Bryan's workday with a summary of progress and tomorrow's priorities.

## Configuration

```
VAULT_PATH="$HOME/notes/workday"
GITHUB_USER="bryan-thompsoncodes"
GITHUB_ORG="department-of-veterans-affairs"
PRIMARY_REPO="vets-website"
```

---

## Step 1: Capture Progress

- Re-check sprint board for status changes since morning
- Note completed items, moved tickets

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

---

## Step 2: Final PR Check

- Check CI status on open PRs
- Note any new reviews or comments

```bash
gh pr list \
  --author bryan-thompsoncodes \
  --repo department-of-veterans-affairs/vets-website \
  --json number,title,url,statusCheckRollup,reviews,comments \
  --limit 20
```

---

## Step 3: Update Daily Note

Find today's daily note:

```bash
DAY=$(date +%d)
MONTH_ABBREV=$(date +%b)
YEAR=$(date +%Y)
FILENAME="${DAY}${MONTH_ABBREV}${YEAR}.md"
VAULT_PATH="$HOME/notes/workday"
NOTE_PATH="${VAULT_PATH}/daily/${FILENAME}"
```

Write to "End of Day" section:

```markdown
## End of Day
*EOD sync: {date} @ {time} PT*

### What Got Done Today
- Item 1
- Item 2

### What's Still In Flight
- Item with status

### Blockers / Awaiting Response
- Blocker description

### Review Queue (remaining)

| PR | Author | Status |
|----|--------|--------|
| #xxx | Author | Status |

### Tomorrow
- Priority 1
- Priority 2
```

Use Obsidian wikilinks: `[[Note Name]]` or `[[Note Name|display text]]`
