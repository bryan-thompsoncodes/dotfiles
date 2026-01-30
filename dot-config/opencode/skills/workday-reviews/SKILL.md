---
name: workday-reviews
description: Check PRs awaiting Bryan's review - prioritized by age and CI status
---

# Review Queue Check

Check pull requests awaiting Bryan's review.

## Configuration

```
GITHUB_USER="bryan-thompsoncodes"
GITHUB_ORG="department-of-veterans-affairs"
PRIMARY_REPO="vets-website"
```

---

## Execution

Fetch PRs where Bryan's review is requested:

```bash
gh pr list \
  --search "review-requested:bryan-thompsoncodes" \
  --repo department-of-veterans-affairs/vets-website \
  --json number,title,author,createdAt,url,statusCheckRollup,reviews,isDraft \
  --limit 20
```

---

## Processing Logic

For each PR:

1. **Check if already reviewed** - Skip if Bryan has already submitted a review (unless dismissed)
2. **Check CI status** - Note if passing, failing, or pending
3. **Calculate age** - Days since PR was created
4. **Determine priority**

### Skip Criteria

Skip PRs that match:
- Draft PRs
- CI failing (note as "CI failing")
- Stale (2+ months old)
- Already reviewed by Bryan

---

## Output Format

| PR | Title | Author | Age | CI | Action |
|----|-------|--------|-----|----| -------|
| #xxx | Title | @author | Xd | ✅/❌ | Review / Skip: reason |

### Prioritization

Order by:
1. Passing CI, oldest first
2. Pending CI
3. Failing CI (informational only)

### Summary

- **Ready for review:** N PRs with passing CI
- **Blocked:** N PRs with failing CI
- **Skipped:** N PRs (with reasons)

### Offer PR Review

For top priority PRs (passing CI, not draft), offer:

> Would you like me to create a preliminary review for #xxx?

If yes, load the `workday-pr-review` skill.
