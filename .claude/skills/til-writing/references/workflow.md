# TIL Workflow Guide

## Table of Contents

1. [Integration with Deep Learning Mode](#integration-with-deep-learning-mode)
2. [When to Create a TIL](#when-to-create-a-til)
3. [Category Selection](#category-selection)
4. [Filename Generation](#filename-generation)
5. [Post-Creation Checklist](#post-creation-checklist)

---

## Integration with Deep Learning Mode

When `/output-style deep-learning` is active, TIL creation naturally follows learning conversations.

### Transition Points

Look for these signals to suggest TIL creation:
- User says "got it" or "makes sense" after explanation
- User successfully applies the concept
- Conversation covered a non-obvious technique
- User discovered a gotcha or edge case

### Suggested Prompts

```
This would make a good TIL entry.
Especially "[key concept]" - easy to forget later.

Want to record it with `/til [category] [topic]`?
```

---

## When to Create a TIL

### Good TIL Candidates

- **New discovery**: Something you didn't know before
- **Non-obvious**: Not easily found in basic tutorials
- **Reusable**: Applicable to future situations
- **Concrete**: Has a specific example or code
- **Gotcha**: A mistake you made and how to avoid it

### Not TIL Material

- Basic syntax you can easily look up
- Opinion without evidence
- Incomplete understanding (wait until you really get it)
- Exact duplicate of existing entry

---

## Category Selection

### Existing Categories First

Check for existing categories before creating new ones:

```bash
ls -d */ 2>/dev/null | grep -v '^\.'
```

### Category Naming Rules

| Rule | Good | Bad |
|------|------|-----|
| Lowercase | `python` | `Python` |
| Hyphens for spaces | `github-actions` | `github_actions` |
| Specific | `postgresql` | `databases` |
| Technology name | `docker` | `containers` |

### Suggested Categories

Common categories for tech TILs:
- `python`, `javascript`, `typescript`, `go`, `rust`
- `git`, `github-actions`
- `docker`, `kubernetes`
- `postgresql`, `mysql`, `sqlite`
- `linux`, `macos`, `bash`
- `vim`, `vscode`
- `aws`, `gcp`, `azure`
- `claude-code`, `llm`

---

## Filename Generation

### Rules

1. Lowercase only
2. Hyphens between words
3. Descriptive but concise
4. No version numbers unless critical

### Examples

| Topic | Filename |
|-------|----------|
| Using UV for Python deps | `using-uv-for-dependencies.md` |
| PostgreSQL RLS | `row-level-security.md` |
| Git switch vs checkout | `git-switch-command.md` |
| Python 3.12 type syntax | `type-parameter-syntax.md` |

### Avoid

- `tip.md`, `note.md` (too generic)
- `how-to-do-x-in-y-with-z.md` (too long)
- `2024-01-15-thing.md` (dates go in git, not filename)

---

## Post-Creation Checklist

After creating a TIL entry:

- [ ] Entry has clear title
- [ ] Introduction explains the "why"
- [ ] Code example is complete and runnable
- [ ] References link to sources
- [ ] Run `python .claude/skills/til-writing/scripts/update_readme.py`
- [ ] Commit with descriptive message

### Commit Message Format

```
til(category): Brief description

- What you learned
- Why it's useful
```

Example:
```
til(python): Add entry on functools.cache

- Memoization decorator available in Python 3.9+
- Much simpler than lru_cache for basic cases
```
