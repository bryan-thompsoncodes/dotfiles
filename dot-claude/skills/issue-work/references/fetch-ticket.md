# Fetching Tickets — CLI Reference

Long-form fetch recipes. The `ticket-analyst` agent uses these. Loaded on demand from SKILL.md.

---

## GitHub

### Auth precheck

```bash
gh auth status || { echo "Run: gh auth login"; exit 1; }
```

### Issue — metadata + body

```bash
gh issue view {N} --repo {owner}/{repo} \
  --json number,title,body,state,labels,assignees,url,createdAt,closedAt,author
```

Fields returned:
- `number`, `title`, `body`, `state` (OPEN/CLOSED)
- `labels` — array of `{name, color, description}`
- `assignees` — array of `{login}`
- `author.login`, `createdAt`, `closedAt`

### Issue — comments

```bash
gh issue view {N} --repo {owner}/{repo} --comments
```

This returns a rendered text view. To get structured JSON for comments (needed for author + timestamp):

```bash
gh api "repos/{owner}/{repo}/issues/{N}/comments" \
  --jq '[.[] | {author: .user.login, created: .created_at, body: .body}]'
```

With pagination for issues with > 30 comments:

```bash
gh api --paginate "repos/{owner}/{repo}/issues/{N}/comments" \
  --jq '.[] | {author: .user.login, created: .created_at, body: .body}'
```

### Pull Request — metadata + review comments

```bash
gh pr view {N} --repo {owner}/{repo} \
  --json number,title,body,state,labels,assignees,url,createdAt,closedAt,mergedAt,author,baseRefName,headRefName,commits,files,reviews,comments
```

Note: `comments` on a PR view returns **issue comments** (the conversation tab). **Review comments** (inline on diff) come from a separate endpoint:

```bash
gh api "repos/{owner}/{repo}/pulls/{N}/comments" \
  --jq '[.[] | {author: .user.login, created: .created_at, path: .path, line: .line, body: .body}]'
```

### Telling an issue from a PR

If the URL path is `/pull/{N}`, it's a PR. If `/issues/{N}`, it's an issue. If you only have a number (from shorthand `owner/repo#N`), try issue first:

```bash
gh issue view {N} --repo {owner}/{repo} 2>/dev/null \
  || gh pr view {N} --repo {owner}/{repo}
```

GitHub numbering is shared between issues and PRs in a repo, so `#123` is unambiguous — it's exactly one of them.

### Rate limits

```bash
gh api rate_limit --jq '.rate'
```

If `remaining < 10` and the fetch will need more calls, stop and report to the user with the reset time. Do not auto-retry past the limit.

---

## Forgejo / Gitea / Codeberg

No official CLI for Forgejo is as reliable as `gh` for comments. Use the REST API directly.

### Auth

```bash
# Safe under `set -u` — the `:-` keeps GITEA_TOKEN-unset from erroring.
# Must match the form in dot-claude/agents/ticket-analyst.md Step 3.
TOKEN="${FORGEJO_TOKEN:-${GITEA_TOKEN:-}}"
if [[ -z "$TOKEN" ]]; then
  echo "Set FORGEJO_TOKEN in your shell env" >&2
  exit 1
fi
AUTH=(-H "Authorization: token $TOKEN")
```

`tea` CLI stores tokens at `~/.config/tea/config.yml`. If the user is logged in via `tea login`, parse the token:

```bash
# Fallback: extract token from tea config for a named login
tea login list --output simple
# yq '.logins[0].token' ~/.config/tea/config.yml   # if yq available
```

### Issue (or PR — Forgejo treats PRs as issues for this endpoint)

```bash
INSTANCE="https://{host}"     # e.g. https://codeberg.org or https://git.example.com
OWNER="{owner}"
REPO="{repo}"
N="{number}"

# Basic issue/PR record
curl -sS "${AUTH[@]}" \
  "$INSTANCE/api/v1/repos/$OWNER/$REPO/issues/$N" \
  | jq '{
      number, title, body, state,
      labels: [.labels[].name],
      author: .user.login,
      created_at, closed_at,
      is_pr: (.pull_request != null),
      html_url
    }'
```

### Comments

```bash
curl -sS "${AUTH[@]}" \
  "$INSTANCE/api/v1/repos/$OWNER/$REPO/issues/$N/comments" \
  | jq '[.[] | {author: .user.login, created: .created_at, body: .body}]'
```

Paginate if needed:

```bash
page=1
while :; do
  resp=$(curl -sS "${AUTH[@]}" \
    "$INSTANCE/api/v1/repos/$OWNER/$REPO/issues/$N/comments?page=$page&limit=50")
  [[ "$resp" == "[]" ]] && break
  echo "$resp"
  page=$((page + 1))
done | jq -s 'add'
```

### PR-specific fields (if `is_pr: true`)

```bash
curl -sS "${AUTH[@]}" \
  "$INSTANCE/api/v1/repos/$OWNER/$REPO/pulls/$N" \
  | jq '{
      base: .base.ref,
      head: .head.ref,
      merged,
      mergeable,
      files_changed: .changed_files
    }'
```

### Review comments (inline diff comments)

```bash
curl -sS "${AUTH[@]}" \
  "$INSTANCE/api/v1/repos/$OWNER/$REPO/pulls/$N/reviews" \
  | jq '[.[] | {author: .user.login, state, submitted_at, body}]'
```

---

## Linked Reference Extraction

Run against the body + every comment body:

```bash
# Use a private temp file — never a predictable path like /tmp/txt
# (race / symlink-clobber risk on multi-user hosts, parallel runs).
scratch=$(mktemp -t issue-work.XXXXXX)
trap 'rm -f "$scratch"' EXIT

# Combine body + all comment bodies into one stream
jq -r '.body'   issue.json    >  "$scratch"
jq -r '.[].body' comments.json >> "$scratch"

# Extract candidates
rg -oE '(?:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)?#[0-9]+|\bhttps?://[^\s)]+\b|\b[a-f0-9]{7,40}\b' "$scratch" \
  | sort -u
```

The SHA pattern `[a-f0-9]{7,40}` will false-match on non-SHA hex (UUIDs, nonces, hash literals in code blocks). Treat unresolvable SHA candidates as silent skips — do not error out.

Categorize each candidate:

| Pattern | Category |
|---|---|
| `^[a-f0-9]{7,40}$` | commit SHA |
| `^#[0-9]+$` | same-repo issue/PR ref |
| `^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[0-9]+$` | cross-repo issue/PR ref |
| starts with `http` | URL — parse for known forges |

### Resolve each — one level deep

**Same-repo ref `#N`** (GitHub):

```bash
gh issue view {N} --repo {owner}/{repo} --json number,title,state,url 2>/dev/null \
  || gh pr view {N} --repo {owner}/{repo} --json number,title,state,url
```

**Cross-repo `other-owner/other-repo#N`** (GitHub):

```bash
gh issue view {N} --repo {other-owner}/{other-repo} --json number,title,state,url 2>/dev/null \
  || gh pr view {N} --repo {other-owner}/{other-repo} --json number,title,state,url
```

**Commit SHA** — only if the repo is cloned locally:

```bash
git -C "$LOCAL_CLONE" log -1 --format='%h %s' "{sha}" 2>/dev/null
```

If not cloned, skip silently.

**Arbitrary URL** — fetch title with `WebFetch` (cheap, optional). Skip on failure.

**SSRF guardrail.** The URL regex matches anything `https?://...` in the ticket body, including attacker-chosen internal targets (e.g. `http://169.254.169.254/latest/meta-data`, RFC1918 addresses, `localhost`). "Only fetch the title" narrows the leak surface but does not close it — error messages, redirect chains, and timing still exfiltrate signal. Before calling `WebFetch`, allowlist the host:

```bash
# Assumes this block runs inside a `for url in "${urls[@]}"; do ... done`
# loop — the `continue` below only has meaning with a surrounding loop.

# Parse host and strip any :port suffix so `github.com:22` still matches
# the `github.com` allowlist entry.
host=$(printf '%s' "$url" | awk -F/ '{print $3}')
host="${host%%:*}"

# Reject empty hosts outright (e.g. malformed `https:///path` URLs) —
# otherwise they would match an empty "$FORGE_HOST" entry below and slip
# through the allowlist.
if [[ -z "$host" ]]; then
  echo "skip: $url (empty host)"
  continue
fi

# The "$FORGE_HOST" arm is only meaningful when FORGE_HOST is set; the
# empty-host guard above ensures an unset/empty FORGE_HOST cannot match.
case "$host" in
  github.com|*.github.com) ;;                    # GitHub
  codeberg.org|*.codeberg.org) ;;                # Codeberg (Forgejo SaaS)
  "$FORGE_HOST") ;;                              # the ticket's own forge instance
  docs.python.org|developer.mozilla.org|*.readthedocs.io) ;;  # common doc hosts
  *) echo "skip: $url (host $host not on fetch allowlist)"; continue ;;
esac
```

Never expand this usage to fetch bodies or follow chains.

### No-recursion rule

When you resolve a linked ref, only fetch its title + state + url. Do **not** fetch its body, comments, or its own linked refs. Recursion explodes context and rarely helps.

---

## Error-handling summary

| Situation | Action |
|---|---|
| `gh auth status` fails | Stop. Tell user to `gh auth login`. |
| `FORGEJO_TOKEN` missing | Stop. Tell user to set it. |
| 404 on primary ticket | Stop. "Ticket not found. Check URL/access." |
| 403 (rate limit or perms) | Stop. Report rate-limit reset time if present in `X-RateLimit-Reset`. |
| 404 on a linked ref | Record "could not fetch" and continue. |
| Forgejo instance unreachable | Stop. "Cannot reach {host}. Check VPN/network." |
