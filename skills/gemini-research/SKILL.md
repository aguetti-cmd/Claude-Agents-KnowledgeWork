---
name: gemini-research
description: Uses Gemini CLI for real-time research and adversarial code/plan review. Two modes: search (facts, versions, docs) and critique (second opinion on plans or code).
---

# Gemini Research Skill

Two modes: `search` for facts, `critique` for adversarial review of plans or code.

## Invocation

`/gemini-research <mode> <query-or-path>`

- `search`, real-time factual lookup (package versions, documentation, current events)
- `critique`, adversarial review of a plan, code snippet, or architecture decision

If no mode is specified, infer from context. A file path or code block routes to critique. A question routes to search.

## Binary resolution

Resolve the Gemini binary at the start of every invocation. Try the binary on PATH first, fall back to the npm-global wrapper, then fall back to invoking the bundle directly via `node`.

```bash
# 1. Try gemini on PATH, then npm-global wrapper, then npm-configured prefix.
GEMINI_BIN="$(command -v gemini || true)"
if [ -z "$GEMINI_BIN" ] && [ -x "$HOME/.npm-global/bin/gemini" ]; then
  GEMINI_BIN="$HOME/.npm-global/bin/gemini"
fi
if [ -z "$GEMINI_BIN" ] && command -v npm >/dev/null 2>&1; then
  NPM_PREFIX="$(npm config get prefix 2>/dev/null)"
  if [ -n "$NPM_PREFIX" ] && [ -x "$NPM_PREFIX/bin/gemini" ]; then
    GEMINI_BIN="$NPM_PREFIX/bin/gemini"
  fi
fi

# 2. Fall back to node + bundle.js when no gemini wrapper exists.
GEMINI_CMD=""
if [ -n "$GEMINI_BIN" ] && [ -x "$GEMINI_BIN" ]; then
  GEMINI_CMD="$GEMINI_BIN"
else
  BUNDLE="$HOME/.npm-global/lib/node_modules/@google/gemini-cli/bundle/gemini.js"
  if [ -f "$BUNDLE" ]; then
    NODE_BIN="$(command -v node || true)"
    if [ -z "$NODE_BIN" ]; then
      # nvm fallback: pick the highest installed node version.
      NODE_BIN="$(ls -1 "$HOME/.nvm/versions/node" 2>/dev/null | sort -V | tail -1 | xargs -I{} echo "$HOME/.nvm/versions/node/{}/bin/node")"
    fi
    if [ -n "$NODE_BIN" ] && [ -x "$NODE_BIN" ]; then
      GEMINI_CMD="$NODE_BIN $BUNDLE"
    fi
  fi
fi

if [ -z "$GEMINI_CMD" ]; then
  echo "Gemini CLI not found. Run: npm install -g @google/gemini-cli"
  exit 1
fi
```

Use `$GEMINI_CMD` (not `$GEMINI_BIN`) in invocation lines below. It expands to either the wrapper path or `node /path/to/bundle.js`.

### Timeout binary resolution

macOS does not ship GNU `timeout`; with Homebrew coreutils it lands as `gtimeout`. Resolve at the start of every invocation:

```bash
TIMEOUT_BIN="$(command -v timeout || command -v gtimeout || true)"
if [ -z "$TIMEOUT_BIN" ]; then
  echo "No 'timeout' or 'gtimeout' on PATH. Install coreutils: brew install coreutils"
  exit 1
fi
```

Use `$TIMEOUT_BIN` in every invocation below.

### Auth state

The Gemini CLI caches the auth token under `~/.gemini/`. For unattended use, fall back to a `GEMINI_API_KEY` environment variable when the cached login is absent. The cached token is preferred (Google AI Pro plan via `gemini login`); the API key is the unattended-auth fallback.

Pre-flight check:

```bash
# Prefer cached login; fall back to API key for unattended runs.
if [ -d "$HOME/.gemini" ] && [ -n "$(ls -A "$HOME/.gemini" 2>/dev/null)" ]; then
  : # cached auth present
elif [ -n "$GEMINI_API_KEY" ]; then
  export GEMINI_API_KEY
else
  echo "No Gemini auth available. Run 'gemini login' or export GEMINI_API_KEY."
  exit 1
fi
```

## Model selection

Always pin the model. Two aliases (accepted by the CLI as shorthand for the canonical model IDs):

- `auto-gemini-3`, resolves to Gemini 3.1 Pro. Use for critique and deep research.
- `flash`, latest Flash. Use for quick search and factual lookup.

If either alias starts being rejected by the CLI, swap to the canonical model ID returned by `gemini models list`.

## Input size guard

Run the size check before writing anything to disk and before any Gemini call.

For inline content, measure first, then write the temp file only if it passes:

```bash
SIZE=${#CONTENT}
if [ "$SIZE" -gt 204800 ]; then
  echo "Input exceeds 200KB hard limit ($SIZE bytes). Refusing to send."
  exit 1
elif [ "$SIZE" -gt 51200 ]; then
  echo "Warning: input is $SIZE bytes (>50KB). Proceeding."
fi

TMP="$HOME/Documents/01 - Projects/Code/gemini-critique-$(date +%Y%m%d-%H%M%S).md"
printf '%s' "$CONTENT" > "$TMP"
```

For content already on disk:

```bash
SIZE=$(wc -c < "$FILE")
if [ "$SIZE" -gt 204800 ]; then
  echo "Input exceeds 200KB hard limit ($SIZE bytes). Refusing to send."
  exit 1
elif [ "$SIZE" -gt 51200 ]; then
  echo "Warning: input is $SIZE bytes (>50KB). Proceeding."
fi
```

## Working file convention

Leo-to-Gemini pipe files go to:

```
~/Documents/01 - Projects/Code/gemini-critique-{timestamp}.md
```

Format the timestamp as `YYYYMMDD-HHMMSS`. Do not write these files to the vault. Do not write them to `/tmp` (they may be useful for follow-up review).

### Retention

At the start of every critique invocation, prune `gemini-critique-*.md` files older than 7 days:

```bash
find "$HOME/Documents/01 - Projects/Code" -maxdepth 1 -type f -name 'gemini-critique-*.md' -mtime +7 -delete 2>/dev/null
```

## Protocol: Search Mode

1. Identify the core factual query.
2. Choose the input channel by query shape:

   - Short trusted string (no user-pasted content, no unknown shape): pass via `-p`.

     ```bash
     $TIMEOUT_BIN 60 $GEMINI_CMD -m flash -p "QUERY_TEXT" -o text
     ```

   - Anything that is a user-controlled string or has unknown shape (pasted content, multi-line input, anything assembled from external data): write to a temp file and pipe via stdin.

     ```bash
     $TIMEOUT_BIN 60 $GEMINI_CMD -m flash -o text < "$TMP"
     ```

   Rule: `-p` for short trusted strings only, stdin pipe for everything else. Do not combine `-p` with `< /dev/null` (contradictory; if you have a string short enough for `-p`, just pass it).
3. Validate the output (see Output validation below).
4. Present findings with version numbers, URLs, or source references Gemini returns.
5. Flag anything stale or uncertain.

## Protocol: Critique Mode

1. Receive the plan, code, or architecture from context (user paste, file read, or pipe from Leo). If inline, write to the working file path above.
2. Run the size guard.
3. Build the prompt file. The persona and instructions are fixed:

   ```
   You are doing a pre-production review. Assume this runs unattended for one year. Find what breaks first.

   Drop preamble, restatement, and hedging. Return findings as a numbered list with severity tags: [BLOCKER], [MODERATE], [MINOR].

   Cover:
   1. The single biggest failure point.
   2. Any logic gaps.
   3. One thing that will cause problems in production.

   Content follows.
   ---
   ```

4. Concatenate the prompt and the content into a single temp file, then pipe via stdin:

   ```bash
   PROMPT_FILE="$HOME/Documents/01 - Projects/Code/gemini-critique-$(date +%Y%m%d-%H%M%S).md"
   {
     cat /path/to/prompt-template
     echo
     cat "$CONTENT_FILE"
   } > "$PROMPT_FILE"

   $TIMEOUT_BIN 180 $GEMINI_CMD -m auto-gemini-3 -o text < "$PROMPT_FILE"
   ```

   Use a 180s timeout for `auto-gemini-3` (critique). Keep 60s for `flash` (search).

5. Validate the output.
6. Return Gemini's critique verbatim, then add a one-line summary of the sharpest objection.
7. If the critique is shallow or generic, say so and ask whether to refine the prompt.

## Retry and quota handling

Wrap every Gemini call in a 3-attempt exponential backoff loop with delays of 2s, 8s, 30s. ECONNRESET and other transient network errors retry silently. Quota exhaustion on `auto-gemini-3` falls back to `flash` and the output is flagged as a downgrade.

```bash
# gemini_call MODEL TIMEOUT INPUT_FILE
gemini_call() {
  local model="$1" tmo="$2" input="$3"
  local attempt=0 delays=(2 8 30) out exit_code first_line
  local downgraded=0

  while :; do
    out="$($TIMEOUT_BIN "$tmo" $GEMINI_CMD -m "$model" -o text < "$input" 2>&1)"
    exit_code=$?
    first_line="$(printf '%s' "$out" | head -n1)"

    # Quota exhaustion on auto-gemini-3: fall back to flash once.
    if [ "$model" = "auto-gemini-3" ] && [ "$downgraded" -eq 0 ] && \
       printf '%s' "$first_line" | grep -qiE '(quota|rate ?limit|exhausted)'; then
      model="flash"
      tmo=60
      downgraded=1
      continue
    fi

    # Transient: ECONNRESET, network reset, timeout, HTTP 5xx. Retry silently.
    # Anchored to the first line so reviewed content discussing these terms
    # does not trigger a false retry.
    if [ "$exit_code" -ne 0 ] && [ "$attempt" -lt 3 ] && \
       (printf '%s' "$first_line" | grep -qiE 'ECONNRESET|socket hang up|network|reset by peer|(^|[^0-9])(5[0-9]{2})([^0-9]|$)|internal server error|bad gateway|service unavailable|gateway timeout' || [ "$exit_code" -eq 124 ]); then
      sleep "${delays[$attempt]}"
      attempt=$((attempt + 1))
      continue
    fi

    break
  done

  if [ "$downgraded" -eq 1 ]; then
    printf '[NOTE] auto-gemini-3 quota exhausted, downgraded to flash.\n\n'
  fi
  printf '%s\n' "$out"
  return $exit_code
}
```

## Output validation

After every Gemini call, check the result before returning it. The quota/overloaded match is anchored to the first line of output so reviewed code that discusses rate limits does not trigger a false failure.

```bash
OUTPUT="$(gemini_call auto-gemini-3 180 "$PROMPT_FILE")"
EXIT=$?
FIRST_LINE="$(printf '%s' "$OUTPUT" | head -n1)"

if [ $EXIT -ne 0 ] || [ -z "$OUTPUT" ]; then
  echo "Gemini returned no usable output. Check auth or retry."
  exit 1
fi

case "$FIRST_LINE" in
  *"unknown model"*|*"model not found"*|*"invalid model"*)
    echo "Gemini rejected the model alias. Run 'gemini models list' and update the alias in this skill."
    exit 1
    ;;
  *"unauthorized"*|*"authentication"*|*"auth error"*|*"not logged in"*|*"login required"*|*"invalid api key"*|*"api key not valid"*)
    echo "Gemini auth failed. Run 'gemini login' or export a valid GEMINI_API_KEY."
    exit 1
    ;;
  Error:*|*"quota"*|*"overloaded"*)
    echo "Gemini returned no usable output. Check auth or retry."
    exit 1
    ;;
esac
```

Treat exit code 124 (timeout) the same as no output (after the retry loop has already consumed its attempts).

## Piping from Leo

Standard adversarial flow:

1. Leo writes the plan or code to `~/Documents/01 - Projects/Code/gemini-critique-{timestamp}.md`.
2. Invoke: `/gemini-research critique <file path>`.
3. Skill runs the size guard, prepends the critique prompt, pipes via stdin to Gemini with `-m auto-gemini-3`, validates output.
4. Return findings to the conversation.

## Notes

- Use `-o text` for readability.
- The CLI runs against the Google AI Pro plan once authenticated (`gemini login`).
- Do not pass sensitive credentials, API keys, or private data to the CLI.
- If Gemini CLI returns an auth error, tell the user to run `gemini login` in their terminal.
- Never embed a user-controlled string or any input of unknown shape in `-p "..."`. Use `-p` only for short trusted strings; pipe everything else via stdin (see Search Mode).
