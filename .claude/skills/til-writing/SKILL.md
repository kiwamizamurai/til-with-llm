---
name: til-writing
description: Create and manage Today I Learned (TIL) entries following simonw/til format. Use when user wants to document learnings, create TIL entries, or update the TIL index. Triggers on "TIL", "learned", "document this", "write up what I learned", or requests to update README index.
---

# TIL Writing

Create well-structured TIL entries. Each entry = one focused concept.

## Quick Start

```bash
# Create entry
mkdir -p content/<category>
# Write to content/<category>/<topic-slug>.md

# Update index
python .claude/skills/til-writing/scripts/update_readme.py
```

## Entry Structure

```markdown
# Clear Title

Brief explanation (1-2 paragraphs).

## Example

\`\`\`language
working code
\`\`\`

## References

- [Source](url)
```

## Naming

- **Category**: lowercase, hyphens (`python`, `github-actions`)
- **File**: lowercase, hyphens (`using-uv-for-deps.md`)

## Workflow

1. Parse category and topic from arguments
2. Ask user clarifying questions if topic is vague
3. Generate comprehensive draft with:
   - Title
   - Detailed explanation (fill in as much as possible)
   - Code example (if applicable)
   - References (placeholder or real if known)
4. Save as `content/<category>/<topic>.draft.md`
5. Inform user: "Draft saved. Rename to `.md` when ready."

## References

- [Format details](references/format.md) - Complete format guide with examples
- [Workflow guide](references/workflow.md) - Deep-learning integration and best practices

## Scripts

- `scripts/update_readme.py` - Updates README.md index automatically
