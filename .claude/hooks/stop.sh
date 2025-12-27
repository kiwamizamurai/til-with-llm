#!/bin/bash
# TIL stop hook - remind to document learnings

set -e

# Read JSON from stdin
INPUT=$(cat)

# Check if stop hook is already active (prevent infinite loop)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || cd "$(pwd)"

# Read transcript to check if learning happened
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Check if conversation involved learning (simple heuristic)
LEARNING_KEYWORDS=0
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    # Count learning-related keywords in transcript
    LEARNING_KEYWORDS=$(grep -c -i -E "(learned|understand|explain|how does|what is|why does|figured out|realized|discovered|interesting|didn't know)" "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
fi

# If substantial learning conversation, suggest TIL (hint only, no blocking)
if [ "$LEARNING_KEYWORDS" -gt 3 ]; then
    cat <<EOF
{
  "systemMessage": "This conversation had learning moments. Consider: /til <category> <topic>"
}
EOF
else
    echo '{}'
fi

exit 0
