# til-with-llm

My Today I Learned snippets, documented with the help of LLMs.

Originally from [kiwamizamurai/til](https://github.com/kiwamizamurai/til)

Site: https://kiwamizamurai.github.io/til-with-llm/ (built with [Quartz v4](https://quartz.jzhao.xyz/))

## Development

```sh
scripts/build.sh --serve   # http://localhost:8080
```

TIL は `content/<category>/<topic>.md` に置く。`main` への push で GitHub Pages に deploy される。

<!-- count starts -->3<!-- count ends --> TILs so far.

<!-- index starts -->
## python

* [t-stringでSQLインジェクションを型で防ぐ(Python 3.14)](https://kiwamizamurai.github.io/til-with-llm/python/t-string-sql-builder) - 2026-10-06
* [TaskGroup.cancel()で一番早い応答だけを採用する(Python 3.15)](https://kiwamizamurai.github.io/til-with-llm/python/taskgroup-cancel-first-wins) - 2026-10-06
* [add_note()で例外に処理中のファイルと行を書き足す(Python 3.11)](https://kiwamizamurai.github.io/til-with-llm/python/exception-add-note) - 2026-10-05
<!-- index ends -->

## Security Hooks

Claude Code PreToolUse hooks to detect sensitive information. Uses [gitleaks](https://github.com/gitleaks/gitleaks) for API keys/tokens and [RapidFuzz](https://github.com/rapidfuzz/RapidFuzz) for fuzzy matching keywords defined in `blocklist.txt`.
