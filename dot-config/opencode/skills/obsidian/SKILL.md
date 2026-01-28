---
name: obsidian
description: Obsidian vault patterns - wikilinks, iCloud paths, cross-referencing, error handling
---

# Obsidian Skill

Shared patterns for working with Bryan's Obsidian vaults via iCloud.

## Vault Locations

Bryan's vaults are stored in iCloud Mobile Documents:

```
BASE_PATH="/Users/bryan/Library/Mobile Documents/iCloud~md~obsidian/Documents"
```

| Vault | Path | Purpose |
|-------|------|---------|
| Agile6 | `${BASE_PATH}/💙 Agile6` | Work - VA.gov development |
| Burnt Ice | `${BASE_PATH}/🧊 Burnt Ice` | Personal - Game development |

---

## Wikilink Syntax

**ALWAYS use Obsidian wikilinks for cross-referencing within a vault.**

### Link Patterns

| Pattern | Syntax | Example | Use Case |
|---------|--------|---------|----------|
| Basic | `[[Note]]` | `[[GDD]]` | Link to note by name |
| Display text | `[[Note\|text]]` | `[[GDD\|design doc]]` | Custom link text |
| Header | `[[Note#Header]]` | `[[mechanics#Combat]]` | Link to section |
| Header + display | `[[Note#Header\|text]]` | `[[mechanics#Combat\|combat system]]` | Section with custom text |
| Block | `[[Note#^block-id]]` | `[[GDD#^core-loop]]` | Link to specific block |
| Embed note | `![[Note]]` | `![[template]]` | Embed full note |
| Embed section | `![[Note#Header]]` | `![[GDD#Summary]]` | Embed specific section |
| Embed image | `![[image.png]]` | `![[diagram.png]]` | Embed image |
| Embed sized | `![[image.png\|300]]` | `![[hero.png\|400]]` | Image with width |

### Best Practices

1. **Prefer wikilinks over markdown links** - `[[Note]]` not `[Note](Note.md)`
2. **Use display text for clarity** - `[[architecture#Signals\|signal patterns]]` reads better
3. **Link to headers when specific** - `[[mechanics#Temperature]]` not just `[[mechanics]]`
4. **Backlink when capturing ideas** - Link new notes back to source docs

### Common Patterns in Output

```markdown
# Good examples
Per [[mechanics#Temperature System]], the range is...
See [[GDD#Core Loop]] for design rationale.
Related: [[roadmap]], [[architecture]]
- Bug affects [[mechanics#Flamethrower|flamethrower]] system

# Avoid
Per mechanics#Temperature System...  (no wikilink)
See [GDD](design/GDD.md)...           (markdown link)
```

---

## Vault Structure Conventions

### Standard Folders (adapt per vault)

| Folder | Purpose |
|--------|---------|
| `design/` | Design documents, specifications |
| `technical/` | Architecture, code patterns |
| `planning/` | Roadmaps, timelines |
| `Calendar/` or `Calendar 🗓️/` | Daily notes |
| `templates/` | Note templates |

### Daily Note Naming

```
# Format: DDMonYYYY.md
27Jan2026.md
03Feb2026.md
```

Locate with:
```bash
DAY=$(date +%d)
MONTH=$(date +%b)
YEAR=$(date +%Y)
FILENAME="${DAY}${MONTH}${YEAR}.md"
```

---

## Error Handling

### Vault Inaccessible

iCloud vaults may be unavailable due to sync issues or path problems.

```bash
# Check if vault exists
VAULT_PATH="/Users/bryan/Library/Mobile Documents/iCloud~md~obsidian/Documents/💙 Agile6"
if [[ ! -d "$VAULT_PATH" ]]; then
  echo "Vault not accessible"
fi
```

**When vault is inaccessible:**

1. Report the specific error to user
2. Check for path escaping issues (spaces, emoji)
3. Try alternate path format:
   ```bash
   # Escaped version
   ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/💙\ Agile6
   ```
4. If still failing, output content to chat instead of file
5. Suggest user check iCloud sync status

### File Write Failures

1. Verify parent directory exists before writing
2. Create directory structure if needed: `mkdir -p "$(dirname "$FILE_PATH")"`
3. Check file permissions
4. Report specific error, don't silently fail

### Path with Emoji/Spaces

Always quote paths containing emoji or spaces:

```bash
# Good
cat "/Users/bryan/Library/Mobile Documents/iCloud~md~obsidian/Documents/💙 Agile6/note.md"

# Bad - will fail
cat /Users/bryan/Library/Mobile Documents/iCloud~md~obsidian/Documents/💙 Agile6/note.md
```

---

## Cross-Vault Considerations

Bryan has multiple vaults. **Do not create links between vaults** - wikilinks only work within a single vault.

If referencing content from another vault:
- Quote the content inline
- Note the source vault for context
- Don't use `[[link]]` syntax for cross-vault references

---

## Templates

When creating notes, check if the vault has templates:

1. Look in `templates/` folder
2. Check for daily note template
3. Use existing template structure if available
4. Preserve YAML frontmatter if present

### Frontmatter Pattern

```markdown
---
created: {date}
tags: [tag1, tag2]
related: [[Note1]], [[Note2]]
---

# Note Title

Content...
```

---

## Integration Notes

This skill provides **shared patterns**. Domain-specific skills should:

1. Load this skill first for Obsidian fundamentals
2. Define their own vault path and link targets
3. Add domain-specific workflows
4. Reference wikilink patterns from this skill

Example in domain skill:
```markdown
## Prerequisites
Load the `obsidian` skill for wikilink patterns and vault handling.

## Vault Configuration
VAULT_PATH="${BASE_PATH}/🧊 Burnt Ice"
```
