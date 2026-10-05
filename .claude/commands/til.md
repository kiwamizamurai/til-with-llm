---
allowed-tools: Bash(mkdir:*), Read, Write, Edit, Glob
argument-hint: <category> <topic-title>
description: Create a TIL draft
---

Create a TIL **draft** using the `til-writing` skill.

**Arguments**: $ARGUMENTS

**Context**:
!`ls -d content/*/ 2>/dev/null | head -20`

Read `.claude/skills/til-writing/SKILL.md` for format.

**Important**:
- Output file: `content/<category>/<topic>.draft.md`
- Generate comprehensive draft from keywords
- Ask user questions if information is missing
- User will manually rename `.draft.md` → `.md` when ready
