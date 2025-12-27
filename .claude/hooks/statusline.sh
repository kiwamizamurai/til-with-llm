#!/bin/bash
# TIL statusline - shows monthly TIL counts and session info

set -e

# Read JSON from stdin
INPUT=$(cat)

# Extract values using jq (new format)
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "unknown"')
CONTEXT_SIZE=$(echo "$INPUT" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$INPUT" | jq '.context_window.current_usage')

# Calculate context usage
if [ "$USAGE" != "null" ]; then
    CURRENT_TOKENS=$(echo "$USAGE" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    CONTEXT_PCT=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
else
    CONTEXT_PCT=0
fi

# Color codes
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Context color based on usage
if [ "$CONTEXT_PCT" -gt 80 ]; then
    CTX_COLOR=$RED
elif [ "$CONTEXT_PCT" -gt 60 ]; then
    CTX_COLOR=$YELLOW
else
    CTX_COLOR=$GREEN
fi

# Count TILs for this month and last month
THIS_MONTH=$(date +%Y-%m)
LAST_MONTH=$(date -v-1m +%Y-%m 2>/dev/null || date -d "1 month ago" +%Y-%m 2>/dev/null || echo "")

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || cd "$(pwd)"

# Count TILs by git commit date
THIS_MONTH_COUNT=0
LAST_MONTH_COUNT=0

# Find all markdown files (excluding README, CLAUDE.md, and .claude directory)
while IFS= read -r -d '' file; do
    # Get the commit date when file was added
    COMMIT_DATE=$(git log --follow --format=%cs --diff-filter=A -- "$file" 2>/dev/null | tail -1)
    if [[ -n "$COMMIT_DATE" ]]; then
        FILE_MONTH="${COMMIT_DATE:0:7}"
        if [[ "$FILE_MONTH" == "$THIS_MONTH" ]]; then
            ((THIS_MONTH_COUNT++)) || true
        elif [[ "$FILE_MONTH" == "$LAST_MONTH" ]]; then
            ((LAST_MONTH_COUNT++)) || true
        fi
    fi
done < <(find . -name "*.md" -type f ! -path "./.claude/*" ! -path "./.git/*" ! -name "README.md" ! -name "CLAUDE.md" -print0 2>/dev/null)

# Total TIL count
TOTAL_COUNT=$(find . -name "*.md" -type f ! -path "./.claude/*" ! -path "./.git/*" ! -name "README.md" ! -name "CLAUDE.md" 2>/dev/null | wc -l | tr -d ' ')

# Format cost
COST_FMT=$(printf "%.2f" "$COST")

# Build status line
# Format: TILs: N (+X this month, +Y last) | Model | $Cost | Context%
echo -e "TILs: ${CYAN}${TOTAL_COUNT}${NC} (${GREEN}+${THIS_MONTH_COUNT}${NC} this month, ${YELLOW}+${LAST_MONTH_COUNT}${NC} last) | ${MODEL} | \$${COST_FMT} | ${CTX_COLOR}${CONTEXT_PCT}%${NC}"

exit 0
