# Customizing

## Personalizing agents

Several agents ship with `[PLACEHOLDER]` fields. These are not required, but agents with personal context are more accurate and need fewer follow-up questions.

| Agent | What to add |
|-------|------------|
| `vera.md` | Your personal context cache. Vera reads this block at invocation to understand your projects, communication style, and goals. Point it at a vault context file or fill it in directly. |
| `nico.md` | Your coaching baseline: current health goals, known avoidance patterns, career direction. |
| `morgan.md` | Your financial baseline: income, fixed expenses, debt structure, savings targets. |
| `dex.md` | Your fitness baseline: available equipment, current program, any injuries or constraints. |
| `miles.md` | Your home city (`[YOUR_BASE_CITY]`) and travel preferences: photography interests, typical trip length, budget range. |

Fill in the files at `~/.claude/agents/` after running the installer.

## Adding a new agent

1. Copy any existing agent `.md` file as a template.
2. Include these required sections:

   - **Frontmatter** (YAML block at the top):
     ```yaml
     ---
     name: [agent-name]
     description: [one-sentence description of when to invoke this agent]
     tools: [comma-separated list of tools]
     model: claude-sonnet-4-6
     ---
     ```
   - **First Response block**: one line the agent says when invoked cold.
   - **Background**: who the agent is and what experience shapes their approach.
   - **Focus**: what tasks this agent handles.
   - **Rules**: hard constraints (what this agent never does).
   - **File system references**: where this agent reads from and writes to.

3. Add the agent to `agents/INDEX.md` with name, file, role, voice rules, and example invocation.
4. If the agent should participate in `/huddle`, add it to the agent list in `skills/huddle/SKILL.md` and update the agent count in `agents/synthesizer.md`.
5. Add the agent to the routing section in `config/CLAUDE.project.md` so Claude knows when to route to it.

Use single first-name convention (Sofia, Marco, Leo) unless the agent is intentionally persona-free (Dex, Morgan, Miles).

## Removing an agent

1. Delete the agent's `.md` file from `agents/`.
2. Remove its row from `agents/INDEX.md`.
3. Remove its routing entry from `config/CLAUDE.project.md`.
4. If it appears in the huddle skill agent list (`skills/huddle/SKILL.md`), remove it there too and update the agent count in that file.

## Changing agent models

Three models in use:

| Model | Use case |
|-------|---------|
| `claude-opus-4-7` | Complex reasoning, critique, synthesis. Vera, Luca, Leo, Kai, Synthesizer. |
| `claude-sonnet-4-6` | Most tasks: writing, research, coaching, planning, distribution. Marcus and all other non-Opus agents. Default for new agents. |
| `claude-haiku-4-5` | Fast, simple tasks with high volume. Giulia (vault filing). |

To change a model, edit the `model:` field in the agent's frontmatter:

```yaml
---
model: claude-opus-4-7
---
```

Use Opus for agents that do multi-step reasoning, produce critique, or evaluate other agents' output. Sonnet for everything else. Haiku only where speed matters more than depth.

## Obsidian vault integration (optional)

Set `VAULT_PATH` in `~/.claude/.env` to enable vault writes.

What it enables:
- Giulia files notes, processes inbox, runs vault hygiene
- Sofia saves research briefs to the vault
- Marco saves drafts to the vault
- Vera writes the task log and context snapshot
- Nico, Marcus, Dex, Morgan write private session logs to their designated vault paths

Without it: all agents still function. Instructions that reference `$VAULT_PATH` are silently skipped or the agent asks where to save output.

If you do not use Obsidian, you can point `VAULT_PATH` at any directory. The agents write plain Markdown files; they do not require Obsidian-specific features.

## Gemini CLI integration (optional)

Enables the `/gemini-research` skill for real-time grounded search and adversarial code review.

Setup:

```bash
npm install -g @google/gemini-cli
gemini login
```

For unattended or automated use, set `GEMINI_API_KEY` in `~/.claude/.env` instead. The skill checks for a cached login first and falls back to the key if not found.

Two modes:
- `search`: factual lookup against live data (package versions, docs, current events)
- `critique`: adversarial review of plans, code, or architecture decisions

Without it: the `/gemini-research` command is unavailable. No other agents are affected.

## Image generation (optional)

Enables the `/generate-image` skill.

Setup:

```bash
pip install google-genai
```

Then set `GOOGLE_API_KEY` in `~/.claude/.env` (get a key from Google AI Studio).

Without it: the `/generate-image` command is unavailable. No other agents are affected.

## Hook customization

Three hooks ship with the repo:

| Hook | Event | What it does |
|------|-------|-------------|
| `check-em-dash.sh` | Stop | Scans Claude's response for em-dashes before delivery. Returns a non-zero exit to flag the violation. |
| `check-auto-memory-write.sh` | PostToolUse (Write/Edit) | Checks whether a Write or Edit call targets the auto-memory path. Blocks agent work products from being written there by mistake. |
| `write-episode.sh` | SessionEnd | Appends a timestamped session log entry to `~/.claude/memory/episodes/`. Retains the 30 most recent episodes and prunes files older than 90 days. |

To disable a hook: remove its entry from the `"hooks"` block in `~/.claude/settings.json`.

To add a custom voice rule (for example, banning a phrase you want to stop using):

1. Copy `check-em-dash.sh` as a template.
2. Replace the em-dash grep pattern with your target string.
3. Register the new hook under the `Stop` event in `settings.json`.

The pattern from `check-em-dash.sh`:

```bash
INPUT=$(cat)
TEXT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response',''))" 2>/dev/null)
echo "$TEXT" | grep -qP "—" && exit 2
exit 0
```

Read stdin, extract the response text, grep for your target pattern. Exit 2 to flag the violation and block delivery. Exit 0 to pass.

Hook scripts live in `~/.claude/hooks/` after install. Edit them directly.
