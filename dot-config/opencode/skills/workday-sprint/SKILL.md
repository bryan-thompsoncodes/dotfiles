---
name: workday-sprint
description: Sprint board snapshot - Bryan's tickets by status (blocked, committed, in progress)
---

# Sprint Board Snapshot

Quick view of Bryan's sprint board status.

## Configuration

```
GITHUB_USER="bryan-thompsoncodes"
GITHUB_ORG="department-of-veterans-affairs"
SPRINT_BOARD_NUMBER=1865
```

---

## Execution

Fetch sprint board items:

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

## Processing Logic

1. Filter for items assigned to `bryan-thompsoncodes`
2. Categorize by status field value
3. Group into standard categories:
   - **Blocked** - Tickets that are blocked
   - **Sprint Commitment** - Committed work for this sprint
   - **In Progress** - Currently being worked on
   - **Ready for Review** - Waiting on PR review
   - **Done** - Completed this sprint

---

## Output Format

### Sprint Status: Bryan's Tickets

| Status | Count | Tickets |
|--------|-------|---------|
| Blocked | N | #xxx - Title |
| Sprint Commitment | N | #xxx - Title |
| In Progress | N | #xxx - Title |
| Ready for Review | N | #xxx - Title |
| Done | N | #xxx - Title |

### Summary

- **Total assigned:** N tickets
- **Completed:** N tickets
- **Remaining:** N tickets
- **Blocked:** N tickets (requires attention)

### Blockers Detail

If any blocked tickets, list them with context:
- #xxx - Title - [Reason if known from comments]
