---
name: sprint-deliverable-update
description: >
  Draft or post sprint updates and final completion summaries on deliverable
  issues, with review-ready evidence and verified screenshot rendering.
version: 2.1.0
author: Bryan Thompson
license: MIT
metadata:
  hermes:
    tags: [sprint, github, google-docs, status-update]
    related_skills: [voice-bryan]
---

# Sprint Deliverable Update

Write either a sprint update or a final completion summary on an individual deliverable
issue (e.g., #7309, #7311, #6195). Classify the artifact before gathering evidence or
drafting; the two formats are not interchangeable.

The project-level rollup that combines all these comments into a board status update
is a separate skill: `sprint-status-update`.

## Key Rules

1. **Always tag Julius.** Open every comment with `@juchang111`. Every time, no exceptions.
2. **ACs and metrics are different things.** Use the bolded name from the deliverable as
   the sub-heading (e.g., "### Custom Fields Catalog", "### SGG Adoption"). Never use
   numbered labels like "Criteria 1", "Criteria 2".
3. **"Criteria completed" is an H2.** Needs visual separation from the sprint update above.
4. **Gather sources before drafting.** The sprint's goal, dates, and committed issue
   list come from the planning doc — not from cadence math or the previous comment. The
   format and voice come from the latest sibling-deliverable updates. See
   **Gather sources first** below.
5. **Final means final.** A draft called complete, post-ready, or review-ready contains
   no editorial instructions, TODOs, placeholders, or suggestions to add evidence later.
6. **Embed or omit.** If the artifact mentions a screenshot, the screenshot must appear
   immediately as a Markdown image. Never write “add,” “attach,” or “consider adding” a
   screenshot in user-facing copy.
7. **Resolve images before handoff.** A review bundle may use relative image paths only
   when every file is packaged beside the Markdown. A post-ready comment must use live
   HTTPS image URLs; `/tmp`, `file://`, and bare local paths are forbidden.

## Choose the artifact type

Classify the request before drafting:

- **Sprint update:** progress during one sprint. Use `## Sprint X.Y updates`, status,
  goal, accomplishments, rollover, risks, next sprint, and optional newly completed
  criteria.
- **Deliverable summary:** final completion evidence for the whole deliverable. Use the
  exact current precedent when the user supplies one. Default to `# Deliverable summary`,
  then `## Acceptance criteria` and `## Metrics`; quote and address every item. Do not
  include sprint goal, rollover, risks, or next-sprint sections.

When the requested format is ambiguous but the user links an established comment, the
linked precedent decides. Do not substitute a familiar sprint-update shape.

## Visual evidence gate

Treat images as part of the artifact, not as follow-up work:

1. Inventory the strongest evidence images before drafting and map each one to the exact
   criterion or metric it proves.
2. Capture or generate the images, then inspect the pixels for legibility, cropping,
   stale claims, credentials, and sensitive data.
3. Embed each accepted image next to its evidence using `![alt text](target)`.
4. Before calling a review artifact ready, run
   `<skill-dir>/scripts/validate-deliverable-comment.py --artifact <deliverable-summary|sprint-update> --mode review --root <bundle-dir> <markdown>`,
   resolving `<skill-dir>` to the absolute directory containing this `SKILL.md`.
   Every relative target must exist in the bundle.
5. Before posting, upload images first and replace every relative target with a live
   HTTPS URL. Run the validator with the same explicit `--artifact` in `post` mode with
   `--check-urls`.
6. After posting, fetch the created comment with GitHub's full JSON media type and verify
   the Markdown image count equals the rendered `<img>` count. Tool success alone is not
   proof that images rendered.

Prefer GitHub user attachments for posted comments. Read
[`references/visual-evidence-and-posting.md`](references/visual-evidence-and-posting.md)
for upload discovery, the GitHub-hosted fallback, and exact verification commands.

**Stop conditions:** Do not ask for review while an image target is unresolved. Do not
repeatedly narrate upload failures to the user. Diagnose one method, switch to a verified
authorized path, and return only when the complete artifact is inspectable.

## Gather sources first

Gather three things, in order, before you draft. They play different roles: the planning
doc is the **input** (what we committed to), the recent sibling comments are the **output
format** to match, and the sub-issues are **what actually happened**.

### 1. The sprint planning Google Doc (the plan)

The P&D team's sprint doc holds the committed goal, dates, and issue list for every sprint:

- Doc ID: `1eTNaLYWsXn1oRU0TB3KRXyTYRHI4oCqf1h-CQBuCo-E`
- URL: https://docs.google.com/document/d/1eTNaLYWsXn1oRU0TB3KRXyTYRHI4oCqf1h-CQBuCo-E/edit

Fetch it through the active agent's authenticated Google Workspace integration. In
Hermes, load `google-workspace` and use its Docs read command; save the JSON/text response
to a temporary file rather than returning the whole document into context. **It is ~107k
chars. Do not read it whole.** Extract only the current sprint's block — from
`## **Sprint X.Y** (dates)` to the next `## ` heading — with a small script or delegate
the saved file to a read-only subagent that returns only that block.

From the sprint block, pull (these OVERRIDE guesses — do not compute the sprint window
from cadence math or lift the goal from last sprint's "Next sprint" section):

- **Sprint number + date range** from the header (e.g. `## **Sprint 6.5** (Jun 24 - Jul 07)`)
  — this is the exact `SPRINT_START_DATE` for the sub-issue filter.
- **The `### *Goal:*` line** — the one-sentence sprint goal → the "Sprint goal" section.
- **The committed issue list under this deliverable** — the workstream-grouped bullets
  beneath the deliverable's top-level bullet. This is what we committed to; reconcile it
  against what actually closed (step 3) to split Accomplishments vs. Rollover.
- **`(carryover from X.Y)` annotations** — rollover context.

From the **Quad's "Checkpoint Planning" table** (top of the current Quad section), pull the
**deliverable → epic-issue mapping**. As of Quad 6: SDK Plugin Enhancements → #8765,
Community Stewardship & Co-Planning → #8757, New Routes & Models → #8692, catch-all → #6265.
Derive it from the table each run — it changes every Quad.

Export gotchas: the exported Markdown is mangled (stray `\` and `*`, mojibake emoji). Parse
issue numbers from the trailing `/issues/NNN` URL, not the `(\#NNN)` link text, and don't
trust emoji read from the export.

If Google Workspace is not authorized (common in a headless or scheduled run), stop and
ask the user to paste the current sprint block. Do not infer it from previous comments.

### 2. Recent sibling-deliverable updates (the format to match)

The house format drifts sprint to sprint. Before drafting, fetch the **latest sprint update
comment from every sibling deliverable epic** (the mapping from step 1 — currently #8765,
#8757, #8692, #6265) to match the current format, voice, and status conventions, and for
cross-deliverable context:

```bash
gh issue view {NUMBER} --repo HHS/simpler-grants-gov --json comments \
  --jq '[.comments[] | select(.body | startswith("## Sprint"))] | last | .body'
```

Also read the previous sprint's comment on **this** deliverable for continuity — what was
planned, what rolled over, whether any ACs/metrics were intentionally held back.

### 3. What actually closed (the sub-issues)

Enumerate the deliverable's sub-issues and filter to the sprint window from step 1. See
**When Drafting From Scratch** below for the GraphQL query.

## Sprint update template

```markdown
## Sprint X.Y updates

@juchang111 here's our end-of-sprint report for [deliverable name]. Let us know if you
have any questions!

**Status:** [emoji]

### Sprint goal

- [goal 1]
- [goal 2]

### Accomplishments

- [what got done, with links to PRs/artifacts where helpful]

### Rollover

- [anything that didn't get done, or "None"]

### Risks

- [or "None"]

### Next sprint (Sprint X.Y+1)

- [planned work]
```

## Deliverable summary template

Use this for final completion evidence across the entire deliverable:

```markdown
# Deliverable summary

Summarizes the work on this deliverable and provides evidence for how it satisfies the
acceptance criteria and meets the target metrics. @juchang111 [other established
stakeholders] See below for our evidence of deliverable completion. Please let us know if
there are any questions or clarifications we can provide!

## Acceptance criteria

### [Bolded criterion name]

> - [x] **[Criterion name]:** [Exact criterion text]

[Concrete evidence and links.]

![Descriptive alt text](RESOLVED_IMAGE_TARGET)

## Metrics

### [Bolded metric name]

> - [x] **[Metric name]:** [Exact metric text]

[Concrete evidence and links.]
```

Address every acceptance criterion and metric, including unresolved items. Never mark an
item complete merely to make the summary look finished; use the authoritative issue state
or explicit user direction.

## Criteria Completed

Most sprints, no ACs or metrics are completed. That's normal. If nothing was completed,
the comment ends after "Next sprint" and there is no criteria completed section at all.

Only include this section when ACs or metrics were actually completed that sprint. It
goes at the bottom of the comment, separated as its own H2.

```markdown
## Criteria completed

@juchang111 Here are additional details and evidence for the ACs and metrics that we
marked as completed this sprint. Let us know if you have any questions about these items.

### [Bolded AC name from deliverable]

> - [x] **[AC name]:** The full AC text quoted from the deliverable.

Evidence paragraph with links to artifacts, screenshots, etc.

### [Bolded metric name from deliverable]

> - [x] **[Metric name] (metric):** The full metric text quoted from the deliverable.

Evidence paragraph with links, data, screenshots.
```

### Finding Completed Criteria

1. Fetch the deliverable issue body and find all `- [x]` checkboxes (both ACs and metrics)
2. Compare against the previous sprint's update to see which are newly checked off
3. Include all newly completed items with evidence
4. Also check off the checkbox on the deliverable issue body if it isn't already

```bash
gh issue view {NUMBER} --repo HHS/simpler-grants-gov --json body --jq '.body'
```

## When Drafting From Scratch

If the engineer hasn't posted an update and you're drafting one, look for closed tasks
(sub-issues) during the sprint period.

First, get the issue's node ID:

```bash
gh issue view {NUMBER} --repo HHS/simpler-grants-gov --json id --jq '.id'
```

Then fetch all sub-issues with their state in a single GraphQL query:

```bash
gh api graphql -f query='
  query($id: ID!) {
    node(id: $id) {
      ... on Issue {
        subIssues(first: 50) {
          nodes {
            number
            title
            state
            closedAt
            repository { nameWithOwner }
          }
        }
      }
    }
  }
' -f id="ISSUE_NODE_ID"
```

Filter results for issues closed during the sprint period (closedAt > SPRINT_START_DATE).

Sub-issues may be in either `HHS/simpler-grants-gov` or `HHS/simpler-grants-protocol`.

**Always get user approval before posting.**
