# Resolving a Local Clone for `owner/repo`

Loaded on demand from SKILL.md. Used by the orchestrator (not by `ticket-analyst` — the analyst only fetches ticket data via API).

---

## Why this exists

When the user shares a ticket from `owner/repo`, the skill needs to know where that repo is cloned locally so it can create a worktree there. A remote URL is not enough — the worktree is a local git operation.

---

## Search order

Run in order, short-circuit on first match.

### 1. Exact name under `~/code/`

```bash
TARGET_REPO="{repo}"  # e.g. "apps"
Glob(pattern="$HOME/code/*/.git")
```

For each match, the parent dir basename is the clone name. If the basename == `{repo}`, verify the remote.

The verification pattern must match the **forge host the ticket came from**. Pass the host in as `FORGE_HOST` so Forgejo/Gitea instances resolve too:

```bash
# FORGE_HOST — the host from the ticket URL (e.g. "github.com",
# "codeberg.org", "git.snowboardtechie.com"). Defaults to github.com
# for shorthand refs like owner/repo#N.
FORGE_HOST="${FORGE_HOST:-github.com}"
# Escape dots in the host for regex safety.
FORGE_HOST_RE="${FORGE_HOST//./\\.}"

git -C "$CANDIDATE" remote get-url origin \
  | grep -iE "${FORGE_HOST_RE}[:/]{owner}/{repo}(\.git)?$"
```

The single `[:/]` class covers both HTTPS (`host/owner/repo`) and SSH (`host:owner/repo`) remotes — no need for a separate `git@` branch. If the remote matches, use `$CANDIDATE` as the trunk. Done.

### 2. One directory deeper (org subdirs)

Some users organize as `~/code/{org}/{repo}/`. Check:

```bash
Glob(pattern="$HOME/code/*/*/.git")
```

Same remote verification as above.

### 3. Alternate parents

If still missing, also check (Glob for each):

```bash
$HOME/code/va/*/.git       # VA (Agile6) clones for Bryan
$HOME/projects/*/.git      # fallback
$HOME/src/*/.git           # fallback
```

### 4. Remote URL fallback (any remote, any name)

If no basename match, grep all clones for the remote URL. This catches renamed local dirs:

```bash
# Iterate every .git parent under ~/code/ (1 and 2 levels deep)
shopt -s nullglob  # so missing patterns expand to empty instead of literal
FORGE_HOST="${FORGE_HOST:-github.com}"
for dir in "$HOME"/code/*/.git "$HOME"/code/*/*/.git; do
  parent="$(dirname "$dir")"
  remote=$(git -C "$parent" remote get-url origin 2>/dev/null) || continue
  # Match both host AND owner/repo — a bare "{owner}/{repo}" substring
  # match would false-positive on forks hosted on the wrong forge.
  if [[ "$remote" == *"$FORGE_HOST"*"{owner}/{repo}"* ]]; then
    echo "$parent"
    break
  fi
done
```

If you prefer Claude's built-in tools over shell globbing, use the `Glob` tool for each pattern and loop over the returned paths in the orchestrator instead — never try to embed `Glob` inside a shell command.

---

## Clone-if-missing

If the search returns nothing, **ask the user first**. Do not auto-clone.

Prompt:

```
I don't see {owner}/{repo} cloned locally under:
  - ~/code/
  - ~/code/*/
  - ~/code/va/
  - ~/projects/ / ~/src/

Clone it to ~/code/{repo}? [y/N]
```

On yes:

```bash
gh repo clone {owner}/{repo} "$HOME/code/{repo}"
```

For Forgejo repos, `gh` won't work — prompt the user for the right clone command or use `git clone` with the instance URL.

On no, stop and report: "Cannot proceed without a local clone."

---

## Trunk vs worktree

The resolution above gives you the **trunk** (the main checkout). The `issue-work` skill will then create a **worktree** for the ticket.

Rules:
- Do not create a worktree on top of a worktree. If the resolved path is already a worktree (`.git` is a file, not a dir), find its trunk first:

  ```bash
  git -C "$CANDIDATE" rev-parse --git-common-dir
  # The git-common-dir is {trunk}/.git — strip /.git for the trunk path
  ```

- All `git fetch`, dirty-tree checks, and default-branch lookups should happen against the trunk.
- The `EnterWorktree` tool handles actual worktree creation; pass it the trunk path, the desired worktree name, and the base branch.

---

## Multi-remote repos

Some repos have both `origin` (forge hosting) and e.g. `upstream` (fork). The ticket's forge should match `origin`. If a repo has the right `upstream` but wrong `origin`, still use it — but fetch from `upstream` instead for the default branch.

Rare edge case. Don't optimize unless it comes up.

---

## Cache (optional future work)

If resolution becomes slow in practice (many cloned repos), consider a tiny cache at `~/.claude/issue-work/.repo-cache.json`:

```json
{
  "anthropics/apps": "/Users/bryan/code/apps",
  "agile6/something": "/Users/bryan/code/va/something"
}
```

Populated on first resolution, invalidated on `gh repo clone` or manual clear. **Skip for now** — premature. Only build if resolution feels slow.
