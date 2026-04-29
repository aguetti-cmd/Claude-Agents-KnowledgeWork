---
name: fact-check
description: Verify a specific factual claim with primary-source citations before [USER] publishes or trusts it. Decomposes the claim into atomic assertions, finds original sources (not commentary), and returns per-atom verdicts. Usage: /fact-check <claim>, or invoke with no argument to fact-check the most recently-discussed factual claim.
allowed-tools: [WebSearch, WebFetch, Read]
---

# Fact-Check Skill

You are running a fact-check pass on a specific claim. The goal is verification against primary sources, not plausibility assessment. [USER] will use this output to decide whether to publish, cite, or discard the claim.

## Input

The claim arrives one of two ways:
1. As an argument after the slash command: treat `$ARGUMENTS` as the claim text.
2. With no argument: pull the most recent factual claim from the active conversation. If no claim is identifiable, ask [USER] to paste it. Do not guess.

If the input is longer than three sentences, restate what you understood as the claim before proceeding, and ask [USER] to confirm or narrow.

## Workflow

### Step 1: Decompose into atoms

Split the claim into atomic verifiable assertions. An atom is a single fact that can be independently confirmed or contradicted: a number, a date, an attribution, a causal link, a definition, a geographic or temporal anchor.

Decomposition guidance:
- Numbers and units stay together (one atom: "GDP grew 2.3% in Q4 2024").
- Multi-clause causal claims split into the cause atom, the effect atom, and the link itself as a third atom if the link is contested.
- Quotations split into: the quote text, the attributed speaker, the date or context.
- If atoms become trivially small (e.g., "the year is 2024" inside a larger claim), merge them back into the parent atom.

Aim for three to seven atoms for a typical sentence-length claim. If you produce more than ten, the decomposition is too fine, merge.

List the atoms before searching. Number them.

### Step 2: Search per atom

For each atom, run one targeted WebSearch designed to surface the original source, not commentary about it.

Search strategy:
- Include exact figures, exact dates, exact proper nouns from the atom in the query.
- Add a domain hint when the source type is obvious: "site:.gov", "site:.edu", "annual report", "press release", "court filing", "peer-reviewed".
- Avoid generic queries that return aggregator and SEO content.

Source priority (use this ranking when picking which result to fetch):
1. Original document or dataset (the cited paper, the filing, the press release, the official transcript).
2. Government (.gov), educational (.edu), official intergovernmental (.europa.eu, .un.org).
3. Established outlets with bylines and dated articles (Reuters, AP, FT, NYT, BBC, etc.).
4. Wikipedia: orientation only. Use it to find the underlying citation, then fetch the citation. Never cite Wikipedia as the final source.

### Step 3: Fetch and verify

WebFetch the top candidate URL per atom. Do not trust search snippets alone, snippets are often truncated or misleading.

Extract the exact supporting or contradicting passage. Quote it verbatim, do not paraphrase.

### Step 4: Failure handling

- **Paywall or auth-required (403, login wall, partial content):** record the URL, note "paywalled, snippet only", quote the search snippet, and mark the atom verdict as "unverifiable, paywalled primary source". Do not silently proceed as if you read the full article.
- **404 or dead link:** try the next-best candidate from the search results. If the top three candidates all fail, mark unverifiable and explain.
- **Sources conflict:** report both, quote both, and mark the atom "contested". Do not pick a winner.
- **No primary source findable:** mark "unverifiable, no primary source surfaced". Suggest one specific search [USER] could try (e.g., "check the agency's bulletin archive directly", "request the original PDF from the issuing body").

### Step 5: Recency and locale caveats

- **Last 24 to 48 hours:** flag explicitly. Search index lag and conflicting early reports are normal. State "recent event, sources may revise".
- **Non-English-language or region-specific claims:** WebSearch is US-biased. State this explicitly when relevant. Suggest the regional or native-language primary source even if you could not fetch it (e.g., a national statistical office, an official gazette, a regional regulator). If a claim hinges on non-English reporting, surface that the verification is partial.

## Output format

Return one block per atom, in this exact structure:

```
ATOM 1: [atom text, verbatim from your decomposition]
VERDICT: confirmed | contradicted | contested | unverifiable
SOURCE: [URL]
SOURCE TIER: [1 original / 2 official / 3 established outlet / 4 other]
QUOTE: "[exact passage from the source]"
NOTES: [optional, only if paywalled, recent, locale-flagged, or otherwise caveated]
```

After all atom blocks, end with a one-line summary:

```
SUMMARY: [N confirmed, N contradicted, N contested, N unverifiable]. Recommend: [publish / revise / hold / discard].
```

The recommendation is mechanical:
- All confirmed: publish.
- Any contradicted: discard or revise.
- Any contested or unverifiable on a load-bearing atom: hold.
- Unverifiable on a peripheral atom (e.g., a non-essential date): publish with caveat noted.

## Constraints

- Quote sources verbatim. Never paraphrase a quote.
- Never fabricate URLs, quotes, or verdicts. If you did not fetch it, say so.
- Do not assess whether the claim is "plausible" or "likely true". This skill verifies, it does not estimate.
- Do not pad. If an atom is confirmed cleanly, the block is five lines.

## Example invocation

`/fact-check Italy's public debt-to-GDP ratio reached 137.3% at end of 2023, per the Bank of Italy.`

Expected decomposition:
- ATOM 1: Italy's public debt-to-GDP ratio at end of 2023 was 137.3%.
- ATOM 2: The figure is sourced to the Bank of Italy.

Expected output: two atom blocks, each with verdict, URL (ideally bancaditalia.it or istat.it), tier, verbatim quote, and a final summary line.
