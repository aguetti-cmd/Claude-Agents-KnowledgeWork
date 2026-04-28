# Installation

## Step 1: Clone and run the installer

```bash
git clone https://github.com/[YOUR_USERNAME]/claude-agents
cd claude-agents && bash install.sh
```

Requirements:
- `claude` CLI
- Node.js + npm
- Python 3 + `google-genai` (`pip install google-genai`, required only for the `/generate-image` skill)
- `coreutils` (macOS only, for `gtimeout`): `brew install coreutils` (required only for the `/gemini-research` skill)

The installer checks for required binaries (claude, node, npm, python3), then prompts for:

| Prompt | Default | Required |
|--------|---------|---------|
| Agents directory | `~/.claude/agents` | Yes |
| Skills directory | `~/.claude/skills` | Yes |
| Hooks directory | `~/.claude/hooks` | Yes |
| Scripts directory | `~/.claude/scripts` | Yes |
| Obsidian vault path | (blank) | No |
| Google API key | (blank) | No |

`GOOGLE_API_KEY` is used by the `/generate-image` skill. For unattended gemini-research use (no interactive login), also set `GEMINI_API_KEY` in `~/.claude/.env`.

What it does:
- Creates target directories
- Copies agents, skills, hooks, and scripts to their directories
- Sets execute permissions on hook scripts
- Substitutes `$VAULT_PATH` into installed files if a vault path was provided
- Writes `~/.claude/.env` with all configured paths and keys

The installer is idempotent. Run it again without `--force` and it skips existing files. Pass `--force` to overwrite.

## Step 2: Merge CLAUDE.md

The repo ships two config templates:

- `config/CLAUDE.global.md`: global rules for `~/.claude/CLAUDE.md`
- `config/CLAUDE.project.md`: project-level rules for the root `CLAUDE.md` of any project

**If you have no `~/.claude/CLAUDE.md` yet:**

```bash
cp config/CLAUDE.global.md ~/.claude/CLAUDE.md
```

**If you already have one:** open both files and merge the sections manually. Do not blindly overwrite. Your existing rules may conflict with sections in the template.

Required sections (the system does not function without these):

- From `config/CLAUDE.global.md` (lives at `~/.claude/CLAUDE.md`): **Voice and Style Rules** is required. Everything else (Depth Triggers, Reasoning Effort, Date Awareness) is optional but recommended.
- From `config/CLAUDE.project.md` (lives at the root `CLAUDE.md` of any project): **Agent Routing** is required for agents to function. Copy this section into the root `CLAUDE.md` of any project where you want agents available.

Repeat the same process for `config/CLAUDE.project.md`, merging into the `CLAUDE.md` at your project root (or using it as the starting point).

If you set a vault path, replace the `$VAULT_PATH` placeholder in the merged section with your actual path (e.g. `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/My Vault`). The installer does not substitute `$VAULT_PATH` in `config/` files because they are merged manually rather than installed.

## Step 3: Register hooks in settings.json

Add the following block to `~/.claude/settings.json`, merging with any existing `"hooks"` key:

```json
"hooks": {
  "Stop": [
    {
      "matcher": "",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/check-em-dash.sh" }]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/check-auto-memory-write.sh" }]
    }
  ]
}
```

Optional: to enable session logging, also add `write-episode.sh` under a `SessionEnd` event. See CUSTOMIZE.md.

## Step 4: Configure personal agents (optional but recommended)

Five agents contain `[PLACEHOLDER]` fields that accept personal context:

| Agent | What to fill in |
|-------|----------------|
| `nico.md` | Your coaching baseline: current goals, known patterns, things to stop avoiding |
| `morgan.md` | Your financial baseline: income, fixed costs, debt, savings targets |
| `dex.md` | Your fitness baseline: equipment, current program, injuries |
| `miles.md` | Your home city and travel preferences |
| `vera.md` | Your personal context cache: projects, communication style, goals |

Open each file in `~/.claude/agents/` and fill in the placeholders. These agents work without customization, but improve substantially with personal context.

Vera also has a `[USER]` block for a personal context cache. If you have an Obsidian vault configured, point `vera.md` at your personal context file. If not, fill it in manually or leave it blank and Vera will ask for context as needed.

## Step 5: Verify

Restart Claude Code, then:

```
Vera: what agents are available?
```

```
/huddle should I adopt this new tool?
```

If Vera responds and the huddle runs, the install worked.

## Step 6: Troubleshooting

**Hooks not firing.** Confirm the JSON block is in `~/.claude/settings.json` under the correct event keys (`Stop`, `PostToolUse`). Test by typing an em-dash in a message and checking if Claude rejects it.

**Agents not responding.** Confirm `agents/` were copied to the directory set during install and that the directory path matches what `CLAUDE.md` references under System Files.

**Vera not routing.** Confirm `config/CLAUDE.project.md` was merged into the project-level `CLAUDE.md` (not just the global one at `~/.claude/CLAUDE.md`). Vera's routing rules live in the project config.
