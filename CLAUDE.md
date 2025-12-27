# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A "Today I Learned" (TIL) repository for documenting learnings with LLM assistance.
Repository: [kiwamizamurai/til-with-llm](https://github.com/kiwamizamurai/til-with-llm)

## Repository Structure

```
til-with-llm/
├── <category>/              # Topic folders (e.g., python/, git/, docker/)
│   └── <topic>.md           # Individual TIL entries
├── .claude/
│   ├── skills/til-writing/  # TIL formatting skill
│   ├── agents/              # Custom subagents
│   ├── commands/            # Slash commands
│   ├── output-styles/       # Custom output styles
│   └── rules/               # Project rules
├── .mcp.json                # MCP servers (Playwright, Context7)
├── README.md                # Index of all TILs (auto-generated)
└── CLAUDE.md
```

## Hooks

- **PreToolUse**: gitleaks (secrets) + RapidFuzz (`blocklist.txt` keywords) before git commit
- **SessionStart**: Shows TIL stats and encouragement
- **Stop**: Suggests creating TIL if learning detected in conversation
- **StatusLine**: Monthly TIL counts, model, cost, context usage

## MCP Servers

- **Playwright**: Headless browser for deep web exploration
- **Context7**: Up-to-date library documentation and code examples

## Output Style

Run `/output-style deep-learning` to enable interactive learning mode.

## Agents

Use the `web-researcher` agent for comprehensive information gathering.

## Workflow

1. `/til <category> <topic>` - Create a new TIL entry
2. `/update-readme` - Update README index

## Conventions

- Category names: lowercase with hyphens (`github-actions`, `python`)
- File names: lowercase with hyphens (`using-uv-for-deps.md`)
- Each entry starts with `# Title`
