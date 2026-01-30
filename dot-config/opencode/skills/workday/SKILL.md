---
name: workday
description: Daily workflow automation router - loads specific workday skills based on trigger
argument-hint: <trigger>
---

# Workday Skill Router

Routes workday requests to the appropriate specialized skill.

## Trigger Detection

Parse the user's message and load the matching skill:

| User Says | Load Skill |
|-----------|------------|
| `morning sync`, `start my day`, `good morning` | `workday-morning` |
| `wrap up`, `end of day`, `EOD` | `workday-eod` |
| `check my PRs`, `my PRs` | `workday-prs` |
| `review queue`, `PRs to review` | `workday-reviews` |
| `sprint status`, `sprint board` | `workday-sprint` |
| `pr review <number>`, `review PR <number>` | `workday-pr-review` |

## Execution

1. Identify the trigger from user's message
2. Load the specific skill: `/skill workday-{action}`
3. Execute the workflow in that skill
4. Report results

---

## Shared Configuration

All workday skills use these values:

```
VAULT_PATH="$HOME/notes/workday"
GITHUB_USER="bryan-thompsoncodes"
GITHUB_ORG="department-of-veterans-affairs"
PRIMARY_REPO="vets-website"
SPRINT_BOARD_NUMBER=1865
```

## Obsidian Vault Structure

```
~/notes/workday/
├── Calendar 🗓️/           ← Daily notes (DDMonYYYY.md)
├── Projects/WIP/          ← Active project docs
├── Agent 🤖/Working/     ← In-progress collaboration
└── Agent 🤖/PR Reviews/  ← Preliminary code reviews
```

## Available Skills

| Skill | Purpose |
|-------|---------|
| `workday-morning` | Full morning sync - daily note, sprint, PRs, priorities |
| `workday-eod` | End of day - progress capture, tomorrow's priorities |
| `workday-prs` | Quick check of Bryan's open PRs |
| `workday-reviews` | PRs awaiting Bryan's review |
| `workday-sprint` | Sprint board snapshot |
| `workday-pr-review` | Create preliminary PR review note |

## Error Handling

### GitHub API Failures
If `gh` commands fail:
1. Check authentication: `gh auth status`
2. Report specific error to user
3. Continue with available data

### Vault Access Issues
If vault path doesn't exist:
1. Check if `~/notes/workday` exists
2. Report error and suggest checking syncthing status
