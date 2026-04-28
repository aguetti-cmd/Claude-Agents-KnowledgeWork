# Vault Write Access

Obsidian vault integration is optional. Set `VAULT_PATH` in your `.env` or skip vault-dependent features.

Claude reads the vault. Claude does not write to the vault, except to designated paths below.

## Whitelisted write paths (agents write directly, no Giulia routing needed)
- Claude + Vera: `02.Areas/AI-Context/context.md`, `02.Areas/AI-Context/context-archive.md`, `02.Areas/AI-Context/vera-log.md`
- Sofia: `03.Resources/AI-Workspace/research/` (research briefs only)
- Ren: `01.Projects/Blog/LinkedIn-adaptations/`, `01.Projects/Blog/distribution-strategies/` (output files only)
- Kai: `03.Resources/AI-Workspace/prompts/`, `03.Resources/AI-Workspace/tools/` (output files only)
- Nico: `02.Areas/AI-Context/Coaching/` (private memory only, Giulia has no access)
- Dex: `02.Areas/AI-Context/Fitness/` (private Training Log only, Giulia has no access)
- Morgan: `02.Areas/AI-Context/Finance/` (private finance memory only, Giulia has no access)
- Miles: `01.Projects/Travel/` (itineraries) and `02.Areas/AI-Context/Travel/` (preferences and options; not private, Giulia can assist with filing)
- Marcus: `02.Areas/AI-Context/Marcus/` (private memory only, no other agent has access)
- Vera: `03.Resources/AI-Workspace/audits/vault-audit-*.md` (audit reports only, read-only elsewhere)
- Leo: `03.Resources/AI-Workspace/code/` (architecture docs, code review notes, technical specs only)
- Claude (huddle skill): `03.Resources/AI-Workspace/huddles/` (huddle documents and huddle-log.md only). Huddle skill also writes to `vera-log.md` (covered by "Claude + Vera" above).

All other vault writes go through Giulia. This includes journal entries, notes, PARA filing, inbox triage, Brain Dump processing, approved content from the pipeline, and any edits to existing vault files outside whitelisted paths.

## Violation protocol
Giulia has a standing mandate to flag any write to the vault outside the whitelisted paths above.
Flag format: `[VAULT VIOLATION] <path> written by <actor> at <timestamp>. Action: <revert | keep | escalate to [USER]>.`
Log violations to `vera-log.md` under a `## Vault Violations` section.
