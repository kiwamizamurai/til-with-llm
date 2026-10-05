# til-with-llm

My Today I Learned snippets, documented with the help of LLMs.

Originally from [kiwamizamurai/til](https://github.com/kiwamizamurai/til)

Site: https://kiwamizamurai.github.io/til-with-llm/ (built with [Quartz v4](https://quartz.jzhao.xyz/))

## Development

```sh
scripts/build.sh --serve   # http://localhost:8080
```

TIL は `content/<category>/<topic>.md` に置く。`main` への push で GitHub Pages に deploy される。

<!-- count starts -->0<!-- count ends --> TILs so far.

<!-- index starts -->
<!-- index ends -->

## Security Hooks

Claude Code PreToolUse hooks to detect sensitive information. Uses [gitleaks](https://github.com/gitleaks/gitleaks) for API keys/tokens and [RapidFuzz](https://github.com/rapidfuzz/RapidFuzz) for fuzzy matching keywords defined in `blocklist.txt`.
