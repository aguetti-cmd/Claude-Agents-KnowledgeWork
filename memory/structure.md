# Memory Architecture

The agent system uses a layered memory model. Three categories of files, each with a defined purpose and lifecycle.

## Categories

### 1. Global memory (`~/.claude/memory/`)

Cross-project knowledge. Lives outside any single project. Two subtypes:

- **Domain** (`domain/{topic}.md`): what things are. Product context, user preferences, APIs, naming conventions, team decisions.
- **Procedural** (`tools/{tool}.md`): how to do things. Deploy steps, test commands, review flows.

Plus:
- `memory.md`: index file. One line per topic file.
- `general.md`: cross-project conventions and preferences.
- `domain/errors.md`: error log for recurring or pattern-worthy failures.

### 2. Project memory (`~/.claude/projects/{mapped-path}/memory/MEMORY.md`)

Per-project state. Created from `templates/MEMORY.md` on first session in a project. Must reference global memory via the `## Global Memory` section. Project-specific notes only. 200-line budget.

### 3. Agent private memory (vault paths)

Each agent that maintains memory across sessions writes to a designated vault path. These paths are private to the agent and are listed in `config/vault-access-rules.md`. Examples:

- Nico (coaching): `02.Areas/AI-Context/Coaching/`
- Marcus (Stoic sparring): `02.Areas/AI-Context/Marcus/`
- Dex (training log): `02.Areas/AI-Context/Fitness/`
- Morgan (finance): `02.Areas/AI-Context/Finance/`

Other agents (Sofia, Marco, Luca, Kai, Ren, Leo) do not maintain private memory. They write work products to dedicated output paths instead.

## Lifecycle

1. **Capture**: write entries immediately. Date, what, why. Nothing more.
2. **Promotion**: when a project memory entry has cross-project value, promote to a global domain or tools file.
3. **Pruning**: review on a cadence. Remove outdated entries. Merge overlapping ones. Split files that grow beyond their topic.

## Auto-memory vs agent work products

`~/.claude/projects/*/memory/` is for ambient cross-session context only (entries with frontmatter `type: user | feedback | project | reference`). Agent work products (coaching logs, research briefs, reports, prompts, evaluations) go to designated vault paths. These are different systems. The `check-auto-memory-write.sh` hook enforces this boundary.

## Templates

- `templates/MEMORY.md`: blank project memory file. Copy on first session in a new project.
- `templates/general.md`: blank global cross-project memory file. Copy once during install if not present.
