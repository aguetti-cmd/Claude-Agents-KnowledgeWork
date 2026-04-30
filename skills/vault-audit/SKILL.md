---
name: vault-audit
description: Run /vault-audit <scope> to audit [USER]'s Obsidian vault and Documents PARA structure for hygiene issues. Scope is "vault", "documents", or "full". Returns a read-only audit report saved to 03.Resources/AI-Workspace/audits/. Use when [USER] asks for a vault audit, a Documents audit, or a full system audit. Trigger on: /vault-audit, "vault audit", "run vault audit", "audit the vault", "audit documents", "documents only", "full audit", "audit everything", "full system". Do not trigger on bare "audit" alone (too ambiguous).
---

# Vault Audit

Read-only audit of [USER]'s Obsidian vault and Documents PARA structure. Outputs a single audit report. Does not modify, move, or delete any file. Recommendations go to [USER], who decides what to route to Giulia.

## Scope inference
- "audit the vault" / "vault only" → vault scope only
- "audit documents" / "documents only" → Documents PARA scope only
- "full audit" / "full system" / "audit everything" → both systems
- Scope unclear → ask one question: "Vault only, Documents only, or full system?" Then proceed immediately on answer.

## Behavioral rules
- Proceed immediately once scope is confirmed. Do not ask clarifying questions beyond scope.
- Read-only except for writing the audit report. Do not modify, move, rename, or delete any file. Do not act on findings.
- Giulia acts on findings. Recommendations go to [USER], who decides what to route.

## Audit checklist (run in this order)

### 1. PARA compliance
- Projects vs Area confusion: items in 01.Projects with no defined endpoint. Items in 02.Areas with a clear deadline (should be Projects).
- Stale Projects: no modification in 30 days → flag at-risk. 60+ days → flag likely dead, recommend archive.
- Resource vs Area confusion: reference material with no ongoing action in 02.Areas (should be Resources).
- Archive hygiene: items in 04.Archive still referenced from active notes.

### 2. Inbox hygiene
- Count items in 00.Inbox/ and Documents/00 - Inbox/. Flag any item older than 7 days.
- Flag items with no frontmatter, no tags, and no links.
- Check Brain Dump files: number of items, last modified.

### 3. Orphaned notes
- Notes with no outgoing links, no tags, and no frontmatter.
- Notes with frontmatter but no body content.

### 4. Metadata and frontmatter
- Notes in 01.Projects or 02.Areas missing created date, tags, or both.
- Inconsistent or misspelled tags.

### 5. Cross-system misplacement
- Markdown files in Documents that appear to be approved content (frontmatter with tags: blog, published, approved).
- Blog articles in vault missing a LinkedIn adaptation or distribution strategy.
- Blog articles without a matching research brief in 03.Resources/AI-Workspace/research/.

### 6. Folder structure
- Files buried more than 3 levels deep inside a PARA category.
- Empty folders.

### 7. System-level
- Items appearing in both Documents and vault (likely incomplete moves).

## Out of scope (always excluded)
- 00.Journal/: journal entries are not PARA content.
- 02.Areas/AI-Context/: system files. Fully excluded from PARA checks.
- Private agent memory: 02.Areas/AI-Context/Coaching/, 02.Areas/AI-Context/Marcus/, 02.Areas/AI-Context/Fitness/, 02.Areas/AI-Context/Finance/. Off-limits.

## Report
Write to: `$VAULT_PATH/03.Resources/AI-Workspace/audits/vault-audit-[YYYY-MM-DD].md`

Create the audits/ directory if it does not exist.

Report frontmatter:
```yaml
---
type: vault-audit
date: [YYYY-MM-DD]
audited-by: vera
scope: [vault / documents / full]
---
```

Report sections (in order): Health Score (A/B/C/D/F + one sentence), Executive Summary (3-5 bullets, most critical only), PARA Compliance, Inbox Status, Orphaned Notes, Metadata Gaps, Cross-System Misplacements, Folder Structure, Flagged for Manual Review, Recommendations (max 7, ordered by impact).

After writing the report, present [USER] with an inline summary: Health Score, top 3 findings, first recommended action, and report path.

Keep the 3 most recent audit reports in audits/. Older reports are archived by Giulia on request.

## Escalation
Flag [ESCALATION] to [USER] when findings require a structural decision beyond routine filing (e.g., PARA category fundamentally misaligned, vault has grown beyond what PARA can handle).
