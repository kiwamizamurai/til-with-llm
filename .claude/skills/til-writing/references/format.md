# TIL Entry Format Guide

## Table of Contents

1. [Basic Structure](#basic-structure)
2. [Title Guidelines](#title-guidelines)
3. [Content Sections](#content-sections)
4. [Code Examples](#code-examples)
5. [Complete Examples](#complete-examples)

---

## Basic Structure

Every TIL entry follows this structure:

```markdown
# Descriptive Title

Introduction paragraph explaining what you learned and why it matters.

## Example

\`\`\`language
// Working code example
\`\`\`

## Key Points (optional)

- Important takeaway 1
- Important takeaway 2

## References

- [Primary source](url)
```

---

## Title Guidelines

**Good titles:**
- `Using UV for Fast Python Package Management`
- `PostgreSQL Row-Level Security with Policies`
- `Git Worktrees for Parallel Development`

**Avoid:**
- `Python Tip` (too vague)
- `How I Fixed The Bug` (not reusable)
- `TIL About...` (redundant - it's already a TIL)

---

## Content Sections

### Introduction (required)
1-2 paragraphs explaining:
- What you learned
- Why it's useful
- When to use it

### Example (highly recommended)
Working code that demonstrates the concept:
- Complete and runnable
- Minimal but sufficient
- Commented if non-obvious

### Key Points (optional)
Bullet points for:
- Gotchas or caveats
- Related concepts
- Performance considerations

### References (recommended)
- Link to official documentation
- Link to article/blog that taught you
- Link to GitHub issue if applicable

---

## Code Examples

### Good Example

```python
# Using functools.cache for memoization (Python 3.9+)
from functools import cache

@cache
def fibonacci(n: int) -> int:
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

# First call computes, subsequent calls use cache
print(fibonacci(100))  # Instant after first computation
```

### What Makes It Good
- Shows import
- Type hints for clarity
- Brief comment explaining behavior
- Demonstrates the benefit

---

## Complete Examples

### Minimal Entry

```markdown
# Using \`git switch\` Instead of \`git checkout\`

Git 2.23 introduced \`git switch\` as a clearer alternative to \`git checkout\` for branch operations.

## Example

\`\`\`bash
# Old way
git checkout -b feature-branch

# New way
git switch -c feature-branch
\`\`\`

## References

- [Git 2.23 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.23.0.txt)
```

### Comprehensive Entry

```markdown
# PostgreSQL JSONB Containment Queries

PostgreSQL's \`@>\` operator checks if a JSONB value contains another. Useful for querying nested JSON without extracting fields.

## Example

\`\`\`sql
-- Find users with specific settings
SELECT * FROM users
WHERE preferences @> '{"theme": "dark"}';

-- Works with nested objects
SELECT * FROM users
WHERE preferences @> '{"notifications": {"email": true}}';

-- Index support for performance
CREATE INDEX idx_users_prefs ON users USING GIN (preferences);
\`\`\`

## Key Points

- \`@>\` is the containment operator (left contains right)
- GIN index makes containment queries fast
- Works with arrays too: \`'["a","b"]'::jsonb @> '["a"]'::jsonb\`

## References

- [PostgreSQL JSON Functions](https://www.postgresql.org/docs/current/functions-json.html)
- [GIN Indexes](https://www.postgresql.org/docs/current/gin-intro.html)
```
