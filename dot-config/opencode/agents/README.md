# OpenCode Agents

Personal AI agent system for thinking, workflow automation, and development assistance.

## Architecture

```
                              ┌─────────────┐
                              │    MUSE     │  ← Primary thinking partner
                              └──────┬──────┘
        ┌──────────────┬─────────────┼─────────────┬──────────────┐
        ▼              ▼             ▼             ▼              ▼
 ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
 │  ARCHIVIST │ │    SAGE    │ │   SCRIBE   │ │    PYRE    │ │ HEPHAESTUS │
 │  (recall)  │ │ (research) │ │  (write)   │ │  (delete)  │ │  (forge)   │
 └────────────┘ └────────────┘ └────────────┘ └────────────┘ └────────────┘

 ┌────────────┐ ┌────────────┐
 │  WORKDAY   │ │  GAMEDEV   │  ← Standalone task agents
 │  (VA.gov)  │ │(Burnt Ice) │
 └────────────┘ └────────────┘
```

## Agent Reference

### Athena System (Thinking + Notes)

The Athena system is centered around **Muse** for exploration and thinking, with specialized subagents for different operations.

| Agent | Model | Purpose | When to Use |
|-------|-------|---------|-------------|
| **Muse** | Opus | Thinking partner, orchestration | Brainstorming, exploring ideas, deep thinking |
| **Archivist** | Haiku | Note retrieval (read-only) | Finding past notes, context recall |
| **Sage** | Sonnet | External research | Web search, library docs, code examples |
| **Scribe** | Sonnet | Note persistence | Creating/updating notes |
| **Pyre** | Sonnet | Note destruction | Deleting notes (with confirmation) |
| **Hephaestus** | Opus | Agent craftsman | Creating/modifying agents and skills |

### Task Agents (Standalone)

These agents operate independently for specific workflows.

| Agent | Model | Purpose | When to Use |
|-------|-------|---------|-------------|
| **Workday** | Sonnet | VA.gov daily workflows | Morning sync, EOD, PR reviews, sprint status |
| **Gamedev** | Sonnet | Burnt Ice development | Dev sessions, playtest notes, phase tracking |

---

## Detailed Agent Descriptions

### Muse - Thinking Partner

**File:** `muse.md`  
**Model:** claude-opus-4-5 (extended thinking: 64k tokens)  
**Mode:** Primary

The central thinking agent. Use Muse when you want to:
- Explore ideas and possibilities
- Work through complex problems
- Brainstorm approaches
- Have a Socratic dialogue

Muse automatically invokes subagents:
- `@archivist` - Recall past notes at session start
- `@sage` - Research external knowledge when needed
- `@scribe` - Capture insights as they emerge
- `@pyre` - Clean up obsolete notes
- `@hephaestus` - Modify agent definitions

**Invocation:** Start a conversation about thinking, exploring, or brainstorming.

---

### Archivist - Context Retrieval

**File:** `archivist.md`  
**Model:** claude-haiku-4-5  
**Mode:** Subagent (invoked by Muse)

Fast, read-only search of notes and working files. Finds:
- Permanent notes in `.notes/`
- Working files in `.notes/.agents/`
- Project-local notes via symlinks

**Invocation (from Muse):**
```
@archivist Find past notes about authentication
@archivist What have I written about API design?
```

---

### Sage - External Knowledge

**File:** `sage.md`  
**Model:** claude-sonnet-4-5  
**Mode:** Subagent (invoked by Muse)

Researches external sources:
- **Web search** - Current articles, opinions, comparisons
- **Library docs** - Official API documentation (via Context7)
- **Code examples** - Real production patterns (via grep.app)

Caches research in `.notes/.agents/sage/` for reuse.

**Invocation (from Muse):**
```
@sage What are current best practices for JWT refresh tokens?
@sage How does React 19 handle Suspense?
```

---

### Scribe - Note Persistence

**File:** `scribe.md`  
**Model:** claude-sonnet-4-5  
**Mode:** Subagent (invoked by Muse)

Writes notes using athena-notes templates:
- **IDEA** - Quick captures
- **EXPLORATION** - Deep dives
- **DECISION** - Choices with rationale
- **SESSION** - Conversation summaries
- **THREAD** - Connected ideas

Also manages working files in `.notes/.agents/`.

**Invocation (from Muse):**
```
@scribe [IDEA] Quick capture about caching strategy
@scribe [DECISION] Record that we chose JWT over sessions
@scribe [EXPLORATION] Document our API design discussion
```

---

### Pyre - Note Destruction

**File:** `pyre.md`  
**Model:** claude-sonnet-4-5  
**Mode:** Subagent (invoked by Muse)

Deletes notes with tiered confirmation:
- **Permanent notes** - Full confirmation required
- **Drafts** - Normal confirmation
- **Working files** - Relaxed confirmation

Can archive instead of delete.

**Invocation (from Muse):**
```
@pyre Delete '.notes/old-auth-approach.md' - superseded
@pyre Clean up task "api-design" - task complete
@pyre Archive task "research-project" instead of deleting
```

---

### Hephaestus - Agent Craftsman

**File:** `hephaestus.md`  
**Model:** claude-opus-4-5 (extended thinking: 32k tokens)  
**Mode:** Subagent (invoked by Muse)

Creates, modifies, and queries agent definitions. Handles:
- Creating new agents
- Improving existing agent instructions
- Creating/modifying skills
- Explaining the agent system

**Invocation (from Muse):**
```
@hephaestus Create a new agent for code review
@hephaestus Improve the archivist's search logic
@hephaestus What agents do I have?
@hephaestus Add the obsidian skill to sage
```

---

### Workday - VA.gov Workflows

**File:** `workday.md`  
**Model:** claude-sonnet-4-20250514  
**Mode:** Standalone

Daily workflow automation for VA.gov development:
- Morning sync (PRs, sprint, priorities)
- End of day summaries
- PR status checks
- Review queue management
- Sprint board snapshots
- PR review note creation

Uses project-local `.notes/` symlinked to `~/notes/workday/{project}/`.

**Triggers:**
```
start my day / morning sync / good morning
end of day / EOD / wrap up
check my PRs / my PRs
review queue / PRs to review
sprint status / sprint board
pr review <number> / review PR <number>
```

---

### Gamedev - Burnt Ice Development

**File:** `gamedev.md`  
**Model:** claude-sonnet-4-20250514  
**Mode:** Standalone

Game development assistant for Burnt Ice (Godot 4.5 roguelike):
- Dev session management
- Phase status tracking
- Playtest note capture
- Design doc reference
- Git workflow (no AI attribution)

Uses project-local `.notes/` symlinked to `~/notes/gamedev/burnt-ice/`.

**Triggers:**
```
dev session / start session / gamedev
phase status / where am I
known issues / bugs
playtest notes
design check <topic>
commit <message>
```

---

## Notes Architecture

### Permanent Notes
```
~/notes/
├── {athena notes}           # Muse explorations, decisions, ideas
├── workday/
│   └── {project}/           # Workday agent notes
└── gamedev/
    └── {project}/           # Gamedev agent notes
```

### Project-Local Pattern
```
~/code/some-project/
├── .notes -> ~/notes/{context}/{project}/   # Symlink (gitignored)
└── ...
```

### Working Files
```
.notes/.agents/
├── muse/{task}/             # Task context
├── sage/{topic}/            # Research cache
├── drafts/                  # Notes not ready for promotion
└── _archive/                # Archived task context
```

---

## Skills

Skills inject domain knowledge into agents.

| Skill | Purpose | Used By |
|-------|---------|---------|
| `athena-notes` | Note templates and patterns | Muse, Scribe, Workday, Gamedev |
| `agent-workspace` | Working directory conventions | All agents |
| `obsidian` | Vault paths, wikilinks, formatting | Muse, Scribe, Workday, Gamedev |
| `workday-*` | Specific workday workflows | Workday |
| `gamedev` | Burnt Ice project context | Gamedev |

---

## Configuration

### Agent Files
`~/.config/opencode/agents/{name}.md`

YAML frontmatter + prose instructions:
```yaml
---
description: One-line description
mode: subagent | primary
model: anthropic/claude-opus-4-5
temperature: 0.2
thinking:
  type: enabled
  budgetTokens: 32000
tools:
  read: true
  write: true
  # ...
skills:
  - skill-name
---

# Agent Name - Role

[Instructions...]
```

### Model Overrides
`~/.config/opencode/oh-my-opencode.json`

Override model, temperature, thinking budget without editing agent files.

---

## Quick Reference

| I want to... | Use |
|--------------|-----|
| Think through a problem | Muse |
| Find past notes | Muse → @archivist |
| Research something external | Muse → @sage |
| Capture an insight | Muse → @scribe (auto) |
| Delete old notes | Muse → @pyre |
| Create/modify an agent | Muse → @hephaestus |
| Start my work day | Workday (`start my day`) |
| End my work day | Workday (`EOD`) |
| Check my PRs | Workday (`check my PRs`) |
| Start a game dev session | Gamedev (`dev session`) |
| Capture playtest notes | Gamedev (`playtest notes`) |
