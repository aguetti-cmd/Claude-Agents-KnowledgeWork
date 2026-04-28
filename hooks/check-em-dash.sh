#!/bin/bash
# Stop hook: blocks any final assistant response containing an em-dash (U+2014).
# Reads the Stop hook JSON from stdin, finds the transcript_path, walks the
# JSONL transcript in reverse to locate the last assistant message, then
# extracts its text and scans for the em-dash character.
#
# Behavior:
#   - em-dash found: print instruction to stderr, exit 2 (Claude continues
#     and must rewrite the response without em-dashes)
#   - clean: exit 0
#   - any parse / IO failure: exit 0 (fail-open, never block on hook bugs)

INPUT=$(cat)

# NOTE: do not use a heredoc here. A heredoc rebinds python's stdin to the
# heredoc body, which would clobber the piped JSON. Pass the program with -c
# instead so the pipe stays connected to python's stdin.
PROG='
import json, os, sys

EM_DASH = "—"

try:
    hook = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)

path = hook.get("transcript_path")
if not path or not os.path.isfile(path):
    sys.exit(0)

try:
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
except Exception:
    sys.exit(0)

# Walk transcript backwards to find the most recent assistant message.
last_asst = None
for line in reversed(lines):
    line = line.strip()
    if not line:
        continue
    try:
        entry = json.loads(line)
    except Exception:
        continue
    if entry.get("type") == "assistant":
        last_asst = entry
        break

if not last_asst:
    sys.exit(0)

msg = last_asst.get("message", {}) or {}
content = msg.get("content")

text_parts = []
if isinstance(content, str):
    text_parts.append(content)
elif isinstance(content, list):
    for block in content:
        if not isinstance(block, dict):
            continue
        btype = block.get("type")
        if btype == "text":
            t = block.get("text", "")
            if isinstance(t, str):
                text_parts.append(t)
        # thinking, tool_use, tool_result, etc. are not user-visible prose; skip.

full_text = "\n".join(text_parts)
if EM_DASH in full_text:
    sys.stdout.write("HIT")
'

VIOLATION=$(printf '%s' "$INPUT" | python3 -c "$PROG" 2>/dev/null)

if [ "$VIOLATION" = "HIT" ]; then
    EM=$(printf '\xe2\x80\x94')
    printf 'Voice rule violation: em-dash detected. Remove all em-dashes (%s) and rewrite the response.\n' "$EM" >&2
    exit 2
fi

exit 0
