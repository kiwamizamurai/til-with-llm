# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A "Today I Learned" (TIL) repository for documenting learnings with LLM assistance.
Repository: [kiwamizamurai/til-with-llm](https://github.com/kiwamizamurai/til-with-llm)
Site: https://kiwamizamurai.github.io/til-with-llm/ ([Quartz v4](https://quartz.jzhao.xyz/) を GitHub Pages に deploy)

## Repository Structure

```
til-with-llm/
├── content/                 # Quartz の公開対象（TIL はすべてここ）
│   ├── index.md             # トップページ
│   └── <category>/          # Topic folders (e.g., python/, git/, docker/)
│       └── <topic>.md       # Individual TIL entries
├── site/                    # Quartz の設定（quartz.config.ts / quartz.layout.ts）
├── scripts/build.sh         # Quartz を取得してビルド・プレビュー
├── .claude/
│   ├── skills/til-writing/  # TIL formatting skill
│   ├── agents/              # Custom subagents
│   ├── commands/            # Slash commands
│   ├── output-styles/       # Custom output styles
│   └── rules/               # Project rules
├── .mcp.json                # MCP servers (Playwright, Context7)
├── .github/workflows/       # GitHub Pages への deploy
├── README.md                # Index of all TILs (auto-generated)
└── CLAUDE.md
```

## Site (Quartz)

- ローカル確認: `scripts/build.sh --serve`（Quartz は `.quartz/` に取得される。バージョンは `scripts/build.sh` の `QUARTZ_VERSION`）
- `main` への push で `.github/workflows/deploy.yml` が GitHub Pages に deploy する
- ノート間は `[[wikilink]]` でリンクでき、バックリンク・グラフが自動生成される
- `*.draft.md` は公開対象外（`site/quartz.config.ts` の `ignorePatterns`）

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

- TIL の地の文は `yomiyasu` スキルで推敲する(`.claude/rules/writing.md`。外部プラグインとして `.claude/settings.json` で参照、上流 `nanaism/yomiyasu` の `v1.0.2` に固定)

- Category names: lowercase with hyphens (`github-actions`, `python`)
- File names: lowercase with hyphens (`using-uv-for-deps.md`)
- TIL は `content/<category>/<topic>.md` に置く
- Each entry starts with front matter `title:` (Quartz のページタイトルになる。本文に `# Title` は書かない)
