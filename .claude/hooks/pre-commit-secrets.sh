#!/bin/bash
# Detect secrets before git commit using gitleaks

set -e

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only check git commit commands
if [[ "$TOOL_NAME" != "Bash" ]] || [[ "$COMMAND" != git\ commit* ]]; then
    exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Check if gitleaks is installed
if ! command -v gitleaks &> /dev/null; then
    echo "Warning: gitleaks not installed. Run 'brew install gitleaks'" >&2
    exit 0
fi

# Run gitleaks on staged files
RESULT=$(gitleaks git --staged --no-banner 2>&1) || true

if echo "$RESULT" | grep -q "leaks found"; then
    echo "BLOCKED: Secrets detected in staged files!" >&2
    echo "$RESULT" >&2
    echo "" >&2
    echo "Fix: Remove secrets and unstage sensitive files" >&2
    echo "Skip: SKIP=gitleaks git commit ..." >&2
    exit 2  # Exit code 2 blocks the tool
fi

exit 0
