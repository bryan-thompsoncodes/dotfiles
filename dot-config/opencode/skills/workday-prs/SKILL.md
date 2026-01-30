---
name: workday-prs
description: Check status of Bryan's open PRs - CI status, review status, blockers
---

# PR Status Check

Quick check of Bryan's open pull requests.

## Configuration

```
GITHUB_USER="bryan-thompsoncodes"
GITHUB_ORG="department-of-veterans-affairs"
PRIMARY_REPO="vets-website"
```

---

## Execution

Fetch all open PRs authored by Bryan:

```bash
gh pr list \
  --author bryan-thompsoncodes \
  --repo department-of-veterans-affairs/vets-website \
  --json number,title,url,state,statusCheckRollup,reviews,isDraft \
  --limit 20
```

---

## Output Format

For each PR, report:

| PR | Title | CI | Reviews | Status |
|----|-------|----|---------| -------|
| #xxx | Title | ✅/❌/⏳ | N approved, N pending | Ready/Blocked/Draft |

### CI Status Key
- ✅ Passing
- ❌ Failing
- ⏳ Pending/Running

### Review Status
- Count of approvals
- Count of pending reviews
- Any "changes requested"

### Actionable Summary

After the table, summarize:
- **Ready to merge:** PRs with passing CI and approvals
- **Needs attention:** PRs with failing CI or requested changes
- **Waiting on reviews:** PRs with passing CI but no approvals yet
