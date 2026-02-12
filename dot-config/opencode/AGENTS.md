# Agent Behavioral Instructions

## Identity & Context

**User:** Bryan Thompson
**Email:** bryan.thompson@agile6.com
**Company:** Agile6
**Role:** Senior Full Stack Engineer
**Working Hours:** 7:30am - 4pm PT
**Timezone:** Pacific

---

## Obsidian Vault Integration

**Vault Path:** `/Users/bryan/Library/Mobile Documents/iCloud~md~obsidian/Documents/💙 Agile6`

| Folder | Purpose |
|--------|---------|
| `Calendar 🗓️/` | Daily notes (format: `DDMonYYYY.md`) |
| `Projects/WIP/` | Active project documentation |
| `Agent 🤖/Working/` | In-progress collaboration state |
| `Agent 🤖/PR Reviews/` | Preliminary code reviews |

**Daily Note Sections:**
- **For Claude** — Tasks user wants help with
- **Claude's Updates** — Agent logs completed work here
- **End of Day** — EOD summary section

**Linking:** Use Obsidian wikilinks `[[Project Name|display text]]`

---

## GitHub Configuration

| Key | Value |
|-----|-------|
| User | `bryan-thompsoncodes` |
| Org | `department-of-veterans-affairs` |
| Primary Repo | `vets-website` |
| Sprint Board | https://github.com/orgs/department-of-veterans-affairs/projects/1865/views/8 |

---

## Git Workflow

**Branch Policy:** Never commit directly to `main` or `master`. All work must be done on a feature branch.

1. **Before any code changes**, check the current branch: `git branch --show-current`
2. If on `main` or `master`, create and switch to a feature branch before making any commits
3. Branch naming: `<type>/<short-description>` (e.g., `feat/add-search`, `fix/header-alignment`, `chore/update-deps`)
4. If the user doesn't specify a branch name, propose one based on the task and confirm before creating
5. **Commit often** — make small, atomic commits as you complete each logical unit of work
6. **Only commit verified work** — confirm changes work as expected (builds pass, tests pass, no regressions) before committing. Never commit just to save progress or "checkpoint"
7. **Never** force push to `main` or `master`
8. **Never** merge into `main` or `master` without explicit user instruction

---

## Repositories & Tech Stack

| Repo | Purpose | Tech |
|------|---------|------|
| vets-website | React frontend for VA.gov | React, Redux, SCSS |
| vets-api | Backend API | Ruby on Rails |
| content-build | Static site generation | Node.js |
| va.gov-cms | Content management | Drupal |

**Testing:** Cypress (E2E), Jest/RTL (unit)
**Feature Flags:** Flipper
**Design System:** VADS (VA Design System)

---

## Team & Contacts

**Agile6 Team:** Alex, Carly, Renata, Tina, Jacky, Dave

**VA/DSVA Contacts:**
- Tim Cosgrove — CMS, cross-environment
- Edmund Dunn — CMS, cross-environment
- Ryan Cook — Tech lead, Forms team

**Support:** Enterprise Service Desk (ESD): (855) 673-4357

---

## Terminology

| Term | Meaning |
|------|---------|
| VA | Department of Veterans Affairs |
| DSVA | Digital Service at VA |
| VAMC | VA Medical Center |
| VADS | VA Design System |
| Flipper | Feature flag system |
| Tugboat | Preview/testing environment |
| CC | Community Care |
| a11y | Accessibility |

---

## Communication Preferences

- Direct and concise
- Code examples over lengthy explanations
- Skip fluff, get to actionable info
- Use existing codebase patterns
- Functional components with hooks
- When referencing files, be explicit about their location — never conflate files loaded as system context with files in the current working repository

---

## LSP Setup Protocol

When I encounter a missing or unavailable LSP:

1. **Pause** before proceeding with workarounds
2. **Check** the project's `.envrc` to identify which nix flake is being used
3. **Ask** the user: "I notice the LSP for [language] is not available. Would you like me to add it to your nix flake at [path]?"
4. **Upon confirmation**, add the appropriate language server package to the flake's `buildInputs`
5. **Suggest** running `direnv reload` to activate the changes
