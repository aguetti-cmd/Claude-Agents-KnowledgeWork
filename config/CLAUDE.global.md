## Learning

Track two types of knowledge:
- Domain: what things are (product context, user preferences, APIs, naming conventions, team decisions)
- Procedural: how to do things (deploy steps, test commands, review flows)

Organize knowledge as a hierarchy of .md files:
- knowledge/index.md routes to categories
- Categories hold the details
- Progressive disclosure: read top-down, only load what you need

Log errors to knowledge/errors.md. Not every error is a mistake:
- Deterministic errors (bad schema, wrong type, missing field): conclude immediately
- Infrastructure errors (timeout, rate limit, network): log, no conclusion until pattern emerges
- Conclusions graduate into the relevant domain or procedural file

Actively manage the knowledge system. This is as important as the current task:
- Review knowledge files at the start of each session
- Merge overlapping categories
- Split files that grow too long
- Remove knowledge that's no longer accurate
- Create new categories when patterns emerge
- When you notice something that should be in CLAUDE.md but isn't (a pattern, a preference, a correction), propose the edit. Don't wait to be asked.

## Memory Implementation

The knowledge hierarchy lives at `~/.claude/memory/`. Vocabulary mapping:

| Learning term | Actual path |
|---|---|
| knowledge/index.md | ~/.claude/memory/memory.md |
| domain category | ~/.claude/memory/domain/{topic}.md |
| procedural category | ~/.claude/memory/tools/{tool}.md |
| cross-project facts | ~/.claude/memory/general.md |
| knowledge/errors.md | ~/.claude/memory/domain/errors.md |

Rules:
1. Write entries immediately. Date, what, why. Nothing more.
2. Before modifying or removing an existing entry, confirm with the user. Propose additions proactively without asking.
3. Keep memory.md current as a one-line-per-file index.

When asked to "reorganize memory":
1. Read all memory files
2. Remove duplicates and outdated entries
3. Merge entries that belong together
4. Split files that cover too many topics
5. Re-sort entries by date within each file
6. Update memory.md index
7. Show a summary of what changed

## Session Start

At the start of every session:
1. Read ~/.claude/memory/memory.md
2. Load topic files only when relevant to the current task
3. Check ~/.claude/projects/{mapped-path}/memory/MEMORY.md, create from the template if absent
4. Flag any project MEMORY.md content worth promoting to a global domain/ or tools/ file. Flag for review only, do not promote without [USER]'s approval.

## Global Memory

Topic files (examples, add as needed):
- ~/.claude/memory/general.md: cross-project conventions and preferences
- ~/.claude/memory/domain/errors.md: error log for recurring or pattern-worthy failures

When a new topic file is added to ~/.claude/memory/, add it to this list only, not to individual project MEMORY.md files.

## Project MEMORY.md

Template for new project memory files lives in `memory/templates/MEMORY.md` in the claude-agents repo.

Rules:
- Must contain a `## Global Memory` section. A short pointer only, not a copy of the topic list.
- 200-line budget. Project knowledge only, no boilerplate.

## Domain Knowledge Lifecycle

1. Staging: knowledge accumulates in `~/.claude/memory/domain/{name}/`
2. Promotion: enough knowledge exists to package as a plugin/skill
3. Pointer: after promotion, the memory file becomes a pointer to the plugin; content lives in the plugin

When an update is needed to a promoted domain, note it in the memory file so an issue can be created on the plugin repo.
