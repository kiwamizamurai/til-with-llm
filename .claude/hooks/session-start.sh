#!/bin/bash
# TIL session start - encourage TIL writing

set -e

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || cd "$(pwd)"

# Count total TILs
TOTAL=$(find . -name "*.md" -type f ! -path "./.claude/*" ! -path "./.git/*" ! -name "README.md" ! -name "CLAUDE.md" 2>/dev/null | wc -l | tr -d ' ')

# Get categories
CATEGORIES=$(find . -maxdepth 1 -type d ! -name ".*" ! -name "node_modules" 2>/dev/null | sed 's|./||' | grep -v '^$' | sort | tr '\n' ', ' | sed 's/,$//')

# Count this month's TILs
THIS_MONTH=$(date +%Y-%m)
THIS_MONTH_COUNT=0
while IFS= read -r file; do
    if [[ -n "$file" ]]; then
        COMMIT_DATE=$(git log --follow --format=%cs --diff-filter=A -- "$file" 2>/dev/null | tail -1)
        if [[ "${COMMIT_DATE:0:7}" == "$THIS_MONTH" ]]; then
            ((THIS_MONTH_COUNT++)) || true
        fi
    fi
done < <(find . -name "*.md" -type f ! -path "./.claude/*" ! -path "./.git/*" ! -name "README.md" ! -name "CLAUDE.md" 2>/dev/null)

# Encouraging messages based on TIL count
if [ "$TOTAL" -eq 0 ]; then
    ENCOURAGE="Let's write your first TIL today!"
elif [ "$THIS_MONTH_COUNT" -eq 0 ]; then
    ENCOURAGE="No TILs this month yet. Time to learn something new!"
elif [ "$THIS_MONTH_COUNT" -lt 5 ]; then
    ENCOURAGE="Keep it up! ${THIS_MONTH_COUNT} TILs this month."
else
    ENCOURAGE="Amazing! ${THIS_MONTH_COUNT} TILs this month!"
fi

# Build context message
CONTEXT="=== TIL Session ===
Total: ${TOTAL} TILs | This month: ${THIS_MONTH_COUNT}
Categories: ${CATEGORIES:-none yet}

${ENCOURAGE}

Quick start: /til <category> <topic>"

# Output JSON with systemMessage (shown to user) and additionalContext (for Claude)
cat <<EOF
{
  "systemMessage": $(echo "$CONTEXT" | jq -Rs .),
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $(echo "$CONTEXT" | jq -Rs .)
  }
}
EOF

exit 0
