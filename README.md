![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

# claude-agents

A production-ready multi-agent system for Claude Code. Fourteen agents (Vera orchestrates), three skills, three hooks, and a layered memory architecture. Drop it into your Claude Code setup, fill in personal placeholders, and get a coordinated assistant system that routes work to the right agent without you managing the pipeline manually.

## Agents

| Name | Role |
|------|------|
| Vera | Orchestrator. Routes multi-agent workflows, rewrites vague briefs. |
| Sofia | Researcher. Builds research briefs, synthesizes sources. |
| Marco | Writer. Drafts and polishes long-form content. |
| Luca | Editor. Mandatory critique gate before any content goes public. |
| Giulia | Vault manager. PARA filing, inbox triage, vault hygiene. |
| Kai | Prompt engineer. Builds and tests prompts, evaluates AI tools. |
| Ren | Distribution. LinkedIn posts, photo captions, distribution strategy. |
| Leo | Coding specialist. Implementation, debugging, code review. |
| Nico | Personal coach. Health, habits, career. Direct invoke only. |
| Marcus | Stoic sparring partner. Applies Stoic principles to real problems. |
| Dex | Home workout coach. 15-min sessions, progressive overload. Direct invoke only. |
| Morgan | Personal finance partner. Budgets, debt paydown, spending filter. Direct invoke only. |
| Miles | Travel planner. Photography-oriented itineraries, packing, budgets. |
| Synthesizer | Huddle synthesis. Reads 13 agent inputs, returns agreements and conflicts. Invoked by `/huddle` only. |

## Skills

| Skill | Invocation | Purpose |
|-------|------------|---------|
| huddle | `/huddle <topic>` | Parallel multi-agent consult with synthesis. Saves decision doc to vault. |
| gemini-research | `/gemini-research <mode> <query>` | Real-time research and adversarial code review via Gemini CLI. |
| generate-image | `/generate-image "prompt"` | Image generation via Gemini image models. |

## Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| check-em-dash.sh | Stop | Flags em-dashes in output before the response is delivered. |
| check-auto-memory-write.sh | PostToolUse (Write/Edit) | Guards the auto-memory path against agent work products. |
| write-episode.sh | SessionEnd | Appends a session log entry to the vault. |

## Quickstart

```bash
git clone https://github.com/[YOUR_USERNAME]/claude-agents
cd claude-agents && bash install.sh
# Merge config/CLAUDE.global.md into ~/.claude/CLAUDE.md (see INSTALL.md)
```

## Requirements

- Claude Code CLI
- Node.js and npm (for gemini-research skill)
- Python 3 (for generate-image skill)
- Obsidian vault (optional; enables vault writes by Giulia, Marco, Sofia, Vera)

## How it works

**Routing.** Three tiers. Claude handles everything directly unless you name an agent. Named agents run directly for single-agent tasks. Vera handles orchestration when you name her: multi-step pipelines, ambiguous briefs, cross-system work. Vera is opt-in. Claude never auto-invokes her.

**Memory.** Two files per session. `~/.claude/memory/memory.md` is the global index with topic files for cross-project knowledge. `~/.claude/projects/{path}/memory/MEMORY.md` holds project-specific notes. Agents with persistent private state (Nico, Marcus, Dex, Morgan) write to designated vault paths.

**Hooks.** Three shell scripts registered in `~/.claude/settings.json`. They run automatically: voice rule enforcement on Stop, memory write guard on file writes, session log on SessionEnd.

---

See [INSTALL.md](INSTALL.md) for full setup and [CUSTOMIZE.md](CUSTOMIZE.md) to adapt agents to your context.
