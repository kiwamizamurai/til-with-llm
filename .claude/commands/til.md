---
allowed-tools: Bash(mkdir:*), Read, Write, Edit, Glob
argument-hint: <category> <topic-title>
description: Create a TIL draft
---

Create a TIL **draft** using the `til-writing` skill.

**Arguments**: $ARGUMENTS

**Context**:
!`ls -d */ 2>/dev/null | grep -v '^\.' | head -20`

Read `.claude/skills/til-writing/SKILL.md` for format.

**Important**:
- Output file: `<category>/<topic>.draft.md`
- Generate comprehensive draft from keywords
- Ask user questions if information is missing
- User will manually rename `.draft.md` → `.md` when ready
