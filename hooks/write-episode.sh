#!/bin/bash
# SessionEnd hook: write an episodic memory file summarizing the session.
# Episodes always written to global ~/.claude/memory/episodes/ regardless of project.

EPISODES_DIR="$HOME/.claude/memory/episodes"

mkdir -p "$EPISODES_DIR"

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H%M)
FILE="$EPISODES_DIR/${DATE}-${TIME}.md"

# Read the JSON payload passed via stdin by Claude Code's SessionEnd hook
# (e.g. {"session_id": "...", "transcript_path": "..."}).
SESSION_INPUT=$(cat 2>/dev/null)

# Parse session_id and transcript_path from the JSON. On empty stdin or parse
# failure, fall back to "unknown" so the episode body is never empty.
PARSED=$(printf '%s' "$SESSION_INPUT" | python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read())
    sid = data.get("session_id", "unknown")
    tpath = data.get("transcript_path", "unknown")
except Exception:
    sid = "unknown"
    tpath = "unknown"
print(f"session: {sid}")
print(f"transcript: {tpath}")
' 2>/dev/null)

if [ -z "$PARSED" ]; then
  PARSED="transcript: unknown"
fi

cat > "$FILE" <<EOF
---
date: $DATE
type: episode
---

# Session $DATE-$TIME

$PARSED
EOF

# Append to promotion-candidates.md (project-scoped, alongside episodes)
CANDIDATES="$EPISODES_DIR/promotion-candidates.md"
touch "$CANDIDATES"
if ! grep -q "${DATE}-${TIME}" "$CANDIDATES"; then
  echo "- [${DATE}-${TIME}]($FILE) review for promotion" >> "$CANDIDATES"
fi

# Enforce 30/90 cap on episode files (excluding promotion-candidates.md)
# 1) Prune any episode older than 90 days
find "$EPISODES_DIR" -maxdepth 1 -type f -name '*.md' \
  ! -name 'promotion-candidates.md' \
  -mtime +90 -delete 2>/dev/null

# 2) If more than 30 episodes remain, delete oldest by filename (timestamped)
#    until count == 30. Filenames sort lexicographically by date-time.
COUNT=$(find "$EPISODES_DIR" -maxdepth 1 -type f -name '*.md' \
  ! -name 'promotion-candidates.md' | wc -l | tr -d ' ')
if [ "$COUNT" -gt 30 ]; then
  EXCESS=$((COUNT - 30))
  find "$EPISODES_DIR" -maxdepth 1 -type f -name '*.md' \
    ! -name 'promotion-candidates.md' | sort | head -n "$EXCESS" | \
    while IFS= read -r f; do rm -f "$f"; done
fi
