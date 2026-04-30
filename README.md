![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

# claude-agents

A multi-agent system for Claude Code. Fourteen named agents, three slash-command skills, three hooks, and a layered memory system. Drop it into your Claude Code setup, fill in personal placeholders, and you get an assistant that routes work to specialized sub-agents instead of trying to do everything in one voice.

Example invocation:

```
Vera: plan my week. Pull from active projects and context.
```

Vera reads your context files, decides which agents are needed, rewrites the brief for each one, and either delegates or runs the task herself.

## Why use this

- One name per job. Marco drafts. Luca critiques. Sofia researches. Giulia files. You stop asking a single agent to do everything.
- Mandatory critique before publishing. Anything going public passes through Luca first. No drafts go out raw.
- Voice rules enforced by hooks. Em-dashes, exclamation marks, and corporate adjectives get caught automatically.
- Memory that persists across sessions. Global topic files plus per-project notes.
- Private agents (coaching, finance, fitness, Stoic sparring) write their own session logs to vault paths separate from the public ones.

## Requirements

- Claude Code CLI
- Node.js and npm (for the `/gemini-research` skill)
- Python 3 with `google-genai` (for the `/generate-image` skill, optional)
- `coreutils` on macOS, for `gtimeout` (for `/gemini-research` only): `brew install coreutils`
- `gh` CLI (only if you want Leo to handle GitHub work)
- Obsidian vault (optional; enables vault writes by Giulia, Marco, Sofia, Vera, and the private-state agents)

## Quickstart

```bash
git clone https://github.com/aguetti-cmd/Claude-Agents-KnowledgeWork
cd Claude-Agents-KnowledgeWork && bash install.sh
```

The installer copies agents, skills, hooks, and scripts to `~/.claude/`, sets executable permissions on hooks, and writes `~/.claude/.env` with your configured paths and keys. It is idempotent. Pass `--force` to overwrite existing files.

After install, three manual steps remain. Full details in [INSTALL.md](INSTALL.md).

1. **Merge `config/CLAUDE.global.md` into `~/.claude/CLAUDE.md`.** Create the file if you do not have one yet. Required section: Voice and Style Rules.
2. **Merge `config/CLAUDE.project.md` into the root `CLAUDE.md` of any project where you want agents available.** Required section: Agent Routing. Vera will not route without this.
3. **Register hooks in `~/.claude/settings.json`.** See INSTALL.md Step 3 for the JSON block.

Verify with:

```
Vera: what agents are available?
/huddle should I adopt this new tool?
```

## How it works

### Routing (three tiers)

The system uses three tiers. You pick the tier by how you address Claude.

1. **Claude direct.** Default. No agent name, no slash command. Claude handles the request itself: questions, code, file ops, lookups. Claude does not auto-invoke agents. If the request is ambiguous, Claude picks the most reasonable interpretation and proceeds.
2. **Direct invoke.** You name an agent (`Marco, draft this`, `Sofia: research X`). The named agent runs the task itself. Use this for single-agent work where the right agent is obvious. Four agents are direct-invoke only and never go through Vera: Nico (coaching), Marcus (Stoic sparring), Dex (workouts), Morgan (finance). Their state is private.
3. **Vera (orchestration).** You name Vera (`Vera: plan my week`). Vera handles multi-agent pipelines, ambiguous briefs that need rewriting, and cross-system work. Vera is opt-in. Claude never auto-invokes her. You can also run Vera as a dedicated session. From the project directory: `claude --agent vera`. The whole session is Vera from turn one.

Once you invoke an agent by name, the persona persists across follow-up turns. You do not re-invoke by name on every message. The persona drops on any of these: another agent named at message start, `//quick`, saying "done" or "back to Claude", a clear topic shift away from that agent's domain, or 3 turns without addressing that agent. When it drops, it does not resume automatically. Re-invoke by name to restart. The four direct-invoke private agents (Nico, Marcus, Dex, Morgan) follow the same persistence rule. For sensitive sessions, start a dedicated Claude Code session rather than mixing with other work.

### Depth and effort triggers

You signal depth and reasoning effort per request, in plain English.

- **Depth.** `//deep` or `deep:` runs the full pipeline with all guardrails. `//quick` or `quick:` returns a short answer with no agent persona and no pipeline. Default depth applies otherwise.
- **Effort.** Phrases like "think harder," "really think," or "max" raise the agent's reasoning effort for that turn. Defaults are set per agent in `agents/INDEX.md`. Effort resets on the next message. The model itself does not change.

### Memory

Memory is split across three locations. Each has a different lifecycle.

**Global memory** at `~/.claude/memory/`:

- `memory.md`: index file. One line per topic file, listing what each one covers.
- `general.md`: cross-project conventions and preferences.
- `domain/{topic}.md`: knowledge about *what things are* (product context, APIs, naming conventions, decisions).
- `domain/errors.md`: error log. Patterns graduate into proper domain files.
- `tools/{tool}.md`: knowledge about *how things work* (deploy steps, test commands, tool quirks).

Agents read `memory.md` at session start to find relevant topic files, then load only what they need.

**Project memory** at `~/.claude/projects/{mapped-path}/memory/MEMORY.md`:

One file per project. Cross-session ambient context: user preferences, project-specific facts, references back to global topic files. Capped at 200 lines. Agents check it at session start and create it from the template if absent.

**Private agent state** in your Obsidian vault (if configured):

Four agents keep private logs separate from the public memory system. They write to dedicated vault paths:

- Nico (coaching): `02.Areas/AI-Context/Coaching/`
- Marcus (Stoic sparring): `02.Areas/AI-Context/Marcus/`
- Dex (workouts): `02.Areas/AI-Context/Fitness/`
- Morgan (finance): `02.Areas/AI-Context/Finance/`

These paths are off-limits to other agents. Without a vault configured, these agents still function but ask where to save logs.

**Knowledge lifecycle.** Domain knowledge stages in `~/.claude/memory/domain/`. When enough has accumulated to package as a skill or plugin, it gets promoted, and the memory file becomes a pointer to the new location. Errors stay in `domain/errors.md` until a pattern emerges, then graduate into the relevant topic file.

**Auto-memory vs work products.** `~/.claude/projects/*/memory/` is for ambient cross-session context only. Agent work products (research briefs, drafts, audit reports, coaching logs) go to vault paths, not the auto-memory path. The `check-auto-memory-write.sh` hook enforces this separation.

### Voice rules

All agents follow the rules defined in `config/CLAUDE.global.md` Voice and Style:

- No em-dashes anywhere
- No exclamation marks, no motivational language, no emoji
- Plain English, short sentences, direct verbs
- No corporate adjectives, no rule-of-three filler

The `check-em-dash.sh` hook scans every response on the Stop event and blocks delivery if an em-dash slips through. CUSTOMIZE.md shows how to add similar hooks for other phrases you want to stop using.

### Hooks

Three shell scripts registered under `"hooks"` in `~/.claude/settings.json`. They run automatically on Claude Code lifecycle events.

| Hook | Event | Purpose |
|------|-------|---------|
| `check-em-dash.sh` | Stop | Scans the response before delivery. Blocks em-dashes. |
| `check-auto-memory-write.sh` | PostToolUse (Write, Edit) | Blocks agent work products from being written to the auto-memory path. |
| `write-episode.sh` | SessionEnd | Appends a session log entry to `~/.claude/memory/episodes/`. Retains the 30 most recent. |

`Stop`, `PostToolUse`, and `SessionEnd` are Claude Code hook events. See the Claude Code docs for the full list.

## Agents

Grouped by tier.

**Orchestrator**

| Name | Role |
|------|------|
| Vera | Routes multi-agent workflows, rewrites vague briefs, runs vault audits on request. |

**Public agents (callable directly or via Vera)**

| Name | Role |
|------|------|
| Sofia | Researcher. Builds research briefs, synthesizes sources. |
| Marco | Writer. Drafts and polishes long-form content. |
| Luca | Editor. Mandatory critique gate before any content goes public. |
| Giulia | Vault manager. PARA filing, inbox triage, vault hygiene, journal entries. |
| Kai | Prompt engineer. Builds and tests prompts, evaluates AI tools. |
| Ren | Distribution. LinkedIn posts, photo captions, distribution strategy. |
| Leo | Coding specialist. Implementation, debugging, code review, GitHub work. |
| Miles | Travel planner. Photography-oriented itineraries, packing, budgets. |

**Direct-invoke only (private state, never via Vera)**

| Name | Role |
|------|------|
| Nico | Personal coach. Health, habits, career. |
| Marcus | Stoic sparring partner. Applies Stoic principles to real problems. |
| Dex | Home workout coach. 15-min sessions, progressive overload. |
| Morgan | Personal finance partner. Budgets, debt paydown, spending filter. |

**System (invoked by skills, not by name)**

| Name | Role |
|------|------|
| Synthesizer | Reads 13 agent inputs from `/huddle`, returns agreements and conflicts. |

## Skills

| Skill | Invocation | Purpose |
|-------|------------|---------|
| huddle | `/huddle <topic>` | Runs 13 agents in parallel on the same topic, then synthesizes. Saves a decision document to the vault. |
| gemini-research | `/gemini-research <mode> <query>` | Real-time grounded search and adversarial code review via Gemini CLI. Modes: `search`, `critique`. |
| generate-image | `/generate-image "prompt"` | Image generation via Gemini image models. |

## Customization

Five agents ship with `[PLACEHOLDER]` fields for personal context (Vera, Nico, Morgan, Dex, Miles). They work without customization but improve with it. See [CUSTOMIZE.md](CUSTOMIZE.md) for adding agents, removing agents, changing models, hook customization, and optional integrations (Obsidian, Gemini CLI, image generation).

## Troubleshooting

**Hooks not firing.** Confirm the JSON block is in `~/.claude/settings.json` under the correct event keys. Test by sending a message containing an em-dash. The response should be blocked.

**Agents not responding.** Confirm `agents/` files are at the path the installer set, and that `CLAUDE.md` references that path under System Files.

**Vera not routing.** Confirm `config/CLAUDE.project.md` was merged into the project-level `CLAUDE.md`, not just the global one. Vera's routing rules live in the project config.

**Vault writes failing.** Confirm `VAULT_PATH` is set in `~/.claude/.env` and points to an existing directory. Without it, vault-writing agents ask where to save instead.

See [INSTALL.md](INSTALL.md) for the full setup walkthrough and [CUSTOMIZE.md](CUSTOMIZE.md) for adapting agents to your context.
