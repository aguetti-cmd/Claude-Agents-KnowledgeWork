#!/bin/bash
# Blocks writes to auto-memory path that don't look like proper memory entries.
# Proper entries have frontmatter: type: user | feedback | project | reference

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

if echo "$FILE_PATH" | grep -qE "/.claude/projects/.+/memory/"; then
    CONTENT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('content', ''))
except:
    print('')
" 2>/dev/null)

    if echo "$CONTENT" | grep -qE "^type: (user|feedback|project|reference)"; then
        exit 0
    else
        echo "BLOCKED: Writing to auto-memory path (~/.claude/projects/*/memory/) but content lacks valid memory frontmatter (type: user | feedback | project | reference)."
        echo "If this is an agent work product (log, report, coaching state, brief), use the correct vault path from vault-access-rules.md instead."
        exit 2
    fi
fi

exit 0
