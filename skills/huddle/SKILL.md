---
name: huddle
description: Run /huddle <topic> to get simultaneous multi-agent perspectives and a synthesized decision document. Launches 13 agents in parallel (Vera, Sofia, Marco, Luca, Giulia, Kai, Ren, Nico, Leo, Marcus, Dex, Morgan, Miles), collects their views, runs a synthesizer, and saves a decision document to the vault with cross-links. Use whenever the user wants a full-system take on a question, decision, or direction before acting. Trigger on: /huddle, "run a huddle on", "get all agents on", "full system view on", "multi-agent take on".
---

# Parallel Huddle

A /huddle gathers simultaneous input from all 13 agents with distinct roles, synthesizes it, and saves a decision document the user can act from.

## Invocation
`/huddle <topic>`

Topic can be a question, decision, direction, or open-ended prompt.

---

## Step 1: Clarify if needed

If the topic is fewer than 5 words or genuinely ambiguous, ask one clarifying question before proceeding. If clear, proceed immediately.

---

## Step 2: Produce 13 role-specific framings

Before spawning agents, reframe the topic through each agent's specific lens:

| Agent | Role lens | Framing angle |
|-------|-----------|---------------|
| Vera | Orchestration and multi-agent workflow | How does this affect routing logic, agent pipelines, and system coordination? What structural changes would follow? What does the current system health and structural audit tell us about readiness for this change? |
| Sofia | Research and knowledge gaps | What information exists on this? What is missing? What sources or evidence should shape the decision? |
| Marco | Writing and content pipeline | What does this mean for drafting, voice consistency, and long-form output? What would the content pipeline need to adapt? |
| Luca | Editorial quality and critique | What are the quality risks? What gates need to be preserved or added? What would a rigorous editor flag before proceeding? |
| Giulia | Vault structure and knowledge management | What does this mean for PARA organization, cross-linking, note structure, and vault hygiene? |
| Kai | Prompt engineering and AI tool fit | What prompt work, tool evaluations, or dependency assessments should accompany this? Where is the current prompt layer weak? |
| Ren | Distribution and public output | How does this affect what gets published, on what channels, and in what format? What distribution implications follow? |
| Nico | Personal coaching: habits, career, performance | What does this mean for the user's energy, habits, and trajectory? What uncomfortable question does it raise? |
| Leo | Technical implementation | What would need to be built, changed, or removed? What is the risk surface and what are the technical dependencies? |
| Marcus | Stoic lens: control, clarity, avoidance | What is actually in the user's control here? What is he trying to avoid by engaging with this question? What is the weakest point in his framing? |
| Dex | Physical performance and energy | What are the energy, recovery, and time-cost implications? How does this interact with training load and sustainable output? |
| Morgan | Financial and cost lens | What is the financial cost: API spend, time investment, opportunity cost? What is the ROI assumption and is it stated? |
| Miles | Logistics, travel, and lifestyle context | Does this affect the user's home base or travel patterns? What lifestyle or mobility constraints are relevant to the decision? |

---

## Step 3: Launch all 13 agents in parallel

Spawn all 13 as simultaneous Agent tool calls in a single message. They must run concurrently, not sequentially.

For each agent, the prompt must include:
1. Skip your First Response block. Skip context loading from disk. Go directly to your perspective on the question below.
2. The role-specific framing of the topic (from Step 2).
3. Your response must: lead with your main point (BLUF), give 3-5 bullets or short paragraphs, take a clear position (no hedging), stay under 300 words.
4. No em-dashes. No corporate adjectives. No filler. No motivational language.
5. Do not quote or reference the contents of your private memory files. Speak from your role lens only, in general terms.
6. This response will be synthesized with 12 other agents. State your clearest view.

Use these subagent_type values: `vera`, `sofia`, `marco`, `luca`, `giulia`, `kai`, `ren`, `nico`, `leo`, `marcus`, `dex`, `morgan`, `miles`.

---

## Step 4: Collect responses

Wait for all 13 to complete. Label each by agent name. If one fails or returns empty, note "no response" for that agent. Do not re-run a failed agent. Proceed with what you have.

---

## Step 4.5: Clean agent responses

Before passing any agent response to the synthesizer or into the document, replace every em-dash with an appropriate alternative: colon, period, semicolon, or comma depending on context. No em-dashes may appear in the saved document or in the synthesizer input. This applies to all 13 responses regardless of source.

---

## Step 5: Synthesize

Spawn a `synthesizer` subagent with all 13 labeled responses as input. The synthesizer will return:
- Agreements
- Conflicts
- Blind spots
- Decision pressure
- Dissenting opinion

Pass this exact instruction along with the responses: "Apply voice rules from CLAUDE.md. No em-dashes. BLUF first. Under 600 words."

---

## Step 6: Build the decision document

Assemble the full huddle document using this exact structure:

```
---
type: resource
title: "Huddle: [topic, max 8 words]"
purpose: "[topic]. Multi-agent synthesis. Decision: [1-sentence decision pressure]."
created: [YYYY-MM-DD]
tags:
  - huddle
  - AI
---

# Huddle: [topic]
Date: [YYYY-MM-DD]
Agents consulted: Vera, Sofia, Marco, Luca, Giulia, Kai, Ren, Nico, Leo, Marcus, Dex, Morgan, Miles

## Decision / Recommendation
[1-3 sentences: what the synthesis says to do or consider. Take a position.]

## Synthesized View

### Agreements
[from synthesizer]

### Conflicts
[from synthesizer]

### Blind Spots
[from synthesizer]

### Decision Pressure
[from synthesizer]

### Dissenting Opinion
[from synthesizer, preserve verbatim if quoted]

---

## Agent Inputs

### Vera
[response]

### Sofia
[response]

### Marco
[response]

### Luca
[response]

### Giulia
[response]

### Kai
[response]

### Ren
[response]

### Nico
[response]

### Leo
[response]

### Marcus
[response]

### Dex
[response]

### Morgan
[response]

### Miles
[response]

---

## Related
[vault files mentioned by agents, as wikilinks. Only include files where an agent gave a specific filename. If no files were mentioned by name, write "None." Do not invent links.]
```

---

## Step 7: Save to vault

Save the document to:
```
$VAULT_PATH/03.Resources/AI-Workspace/huddles/huddle-[YYYY-MM-DD]-[topic-slug].md
```

Where `[topic-slug]` is a lowercase kebab-case version of the topic (max 6 words, remove stop words).

Create the `huddles/` directory if it does not exist.

**Cross-links (do all three):**

1. Add entry to `vera-log.md`:
   ```
   [YYYY-MM-DD HH:MM] - huddle: "[topic]" - file: 03.Resources/AI-Workspace/huddles/huddle-[date]-[slug].md - status: done
   ```
   Path: `$VAULT_PATH/02.Areas/AI-Context/vera-log.md`

2. Append a line to `huddle-log.md` (create if it does not exist):
   ```
   - [YYYY-MM-DD] [[huddle-[date]-[slug]]]: [topic]. Decision: [1-sentence summary of decision pressure]
   ```
   Path: `$VAULT_PATH/03.Resources/AI-Workspace/huddles/huddle-log.md`

3. Inside the huddle document itself, the `## Related` section links to any vault files agents mentioned by name.

---

## Step 8: Report to user

Present in chat:
1. The decision / recommendation
2. Key agreements (2-3 bullets, compressed)
3. The main conflict (1 sentence)
4. The dissenting opinion if meaningful
5. File path

Do not paste the full document into the chat.
