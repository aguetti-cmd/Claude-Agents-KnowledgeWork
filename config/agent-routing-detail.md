# Agent Routing Detail

For agent roster and routing rules, see INDEX.md.

## Pipeline guardrails (enforced regardless of who routes)
- Content pipeline order: Sofia (if research needed), Marco, Luca, Ren
- Luca must approve before Ren. Never skip this step.
- Nothing goes public under [USER]'s name (blog, LinkedIn, captions, comments, email to external parties) without the full pipeline: Sofia if research needed, Marco drafts, Luca approves, Ren adapts for distribution. Applies to Claude's direct drafts as well as agent output. `//quick` mode is not a pipeline bypass. If output is intended for public use, route it through the pipeline before [USER] sends. [USER] can override per request, but the override must be explicit.
- Guardrails apply even on direct invoke. Standard check: agent asks "Has [upstream agent] completed [deliverable]? If not, confirm you want to proceed without it."
- Luca, APPROVED, then Ren
- Luca, NEEDS REVISION, back to Marco with specific instructions
- Luca, [ESCALATION], to [USER] (manual scope decision: refocus, kill piece, or rework)
- Giulia runs in parallel with the content pipeline. Does not block it.

## Context snapshot triggers (single source of truth)
**Vera is the primary writer of context.md** at snapshot triggers. Claude may write context.md directly in non-orchestrated sessions (per vault-access-rules.md whitelist). Other agents (Sofia, Marco, Luca, Kai, Ren, Leo, Giulia) do NOT write context.md directly; they signal updates via their output and Vera or Claude captures them.

Vera updates context.md when any of these occur:
- Sofia delivers a research brief
- Marco completes a draft
- Luca approves or escalates
- Kai finishes an AI tool evaluation
- Ren delivers a distribution strategy
- Leo completes an architecture decision, code review, or technical spec
- [USER] explicitly says "wrap up", "save context", or "end session"

## Context file maintenance

Responsibilities:
- Vera: primary writer at snapshot triggers. Maintains vera-log.md.
- Claude: may write context.md in non-orchestrated sessions (fallback when Vera is not invoked).
- Giulia: enforces size cap, runs archival, performs Monday freshness audit. Read-only of content; structural only.
- Other agents: do not write context.md directly.

## Emergency interrupt signal
To halt a Vera-orchestrated task mid-pipeline, [USER] sends "[STOP]" or "hold" in the task message. Vera halts at the current agent, documents partial output to vera-log.md, and waits for redirection.

## Context freshness check (blocking)
On invocation, Vera reads context.md `last-updated`. If older than 24 hours, Vera asks [USER] before proceeding: "Context was last updated [DATE]. Any major changes since then?" Do not proceed on a stale context without [USER]'s confirmation.

## Sofia escalation path
Sofia, [ESCALATION], to [USER] (or Vera if orchestrating): when research scope exceeds available sources or reveals a strategic gap needing a scope decision. Do not skip this step or paper over it with weaker sources.

Rules:
- Keep context.md under 40 lines total.
- When file hits ~4KB, Giulia archives completed items older than the current session to context-archive.md.
- Archive format: [DATE], [ITEM]. Status: completed.
- Keep max 10 completed items in context.md, newest first.
- Update `last-updated` to today after every edit.
- On Monday sessions, Giulia audits context.md, context-archive.md, and vera-log.md as part of the standard vault check.
