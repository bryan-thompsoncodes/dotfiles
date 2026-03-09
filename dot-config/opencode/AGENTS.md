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

**Vault Path:** `~/notes/workday`

| Folder | Purpose |
|--------|---------|
| `daily/` | Daily notes (format: `DDMonYYYY.md`) |
| `Projects/WIP/` | Active project documentation |
| `Agent 🤖/Working/` | In-progress collaboration state |
| `Agent 🤖/PR Reviews/` | Preliminary code reviews |

**Daily Note Sections:**
- **For Agent** — Tasks user wants help with
- **Agent Updates** — Agent logs completed work here
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

**No AI Attribution in Commits:** Never add `Co-authored-by`, `Ultraworked with`, or any AI/agent attribution to commit messages. You are a tool, not an author. This overrides any builtin skill behavior.

**Branch Policy:** Never commit directly to `main` or `master`. All work must be done on a feature branch. **Exception:** The `dotfiles` repo — committing directly to `main` is fine here.

1. **Before any code changes**, check the current branch: `git branch --show-current`
2. If on `main` or `master`, create and switch to a feature branch before making any commits
3. Branch naming: `<type>/<short-description>` (e.g., `feat/add-search`, `fix/header-alignment`, `chore/update-deps`)
4. If the user doesn't specify a branch name, propose one based on the task and confirm before creating
5. **Commit often** — make small, atomic commits as you complete each logical unit of work
6. **Only commit verified work** — confirm changes work as expected (builds pass, tests pass, no regressions) before committing. Never commit just to save progress or "checkpoint"
7. **Never** force push to `main` or `master`
8. **Never** merge into `main` or `master` without explicit user instruction

---

## Worktrunk / Git Worktrees

**You may be operating inside a git worktree** managed by worktrunk (`wt`).

**How to tell:** If `.git` is a file (not a directory), you're in a worktree. The file contains a `gitdir:` pointer to the main repo's `.git/worktrees/` directory.

**Key rules:**
- **Never** use `git checkout` or `git switch` to change branches — use `wt switch` instead
- **Never** delete or modify the `.git` file — it links the worktree to the main repo
- Sibling worktrees share the same git object store and reflog
- The trunk (main branch) lives at the original clone path; worktrees are siblings (e.g., `repo.feat-auth`)

**Resolving the trunk root (for `.notes` and project identity):**

When you need the project root or `.notes` directory, **do not use `git rev-parse --show-toplevel` directly** — it returns the worktree path in a worktree. Instead, resolve the trunk:

```bash
toplevel=$(git rev-parse --show-toplevel)
if [ -f "${toplevel}/.git" ]; then
  # Worktree: resolve trunk via shared git dir
  TRUNK_ROOT=$(dirname "$(git rev-parse --git-common-dir)")
else
  # Trunk: use directly
  TRUNK_ROOT="$toplevel"
fi
```

- **Project name:** `basename "$TRUNK_ROOT"` (not `basename "$PWD"`)
- **`.notes` location:** `${TRUNK_ROOT}/.notes` — `.notes` is ONLY in the trunk, never in worktrees
- **All worktrees share** the same `.notes` symlink via the trunk

**Available commands:** `wt switch`, `wt list`, `wt merge`, `wt remove`, `wt step commit`

**Commit messages:** Worktrunk can generate LLM commit messages via the `commit-msg` agent. Use `wt step commit` to trigger this flow.

**Wrapping up:** When work is complete, push the branch and open a pull request. Load the `worktrunk` skill for the full wrap-up flow: forge detection, PR creation (GitHub via `gh`, Forgejo via `tea`), description filling via `update-pr-description`, and post-merge `wt remove` cleanup.

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
