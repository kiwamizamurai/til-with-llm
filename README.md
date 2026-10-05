# til-with-llm

My Today I Learned snippets, documented with the help of LLMs.

Originally from [kiwamizamurai/til](https://github.com/kiwamizamurai/til)

Site: https://kiwamizamurai.github.io/til-with-llm/ (built with [Quartz v4](https://quartz.jzhao.xyz/))

## Development

```sh
scripts/build.sh --serve   # http://localhost:8080
```

TIL は `content/<category>/<topic>.md` に置く。`main` への push で GitHub Pages に deploy される。

<!-- count starts -->8<!-- count ends --> TILs so far.

<!-- index starts -->
## python

* [lazy importでCLIの起動を速くする(Python 3.15)](https://kiwamizamurai.github.io/til-with-llm/python/lazy-imports-cli-startup) - 2026-10-06
* [t-stringでSQLインジェクションを型で防ぐ(Python 3.14)](https://kiwamizamurai.github.io/til-with-llm/python/t-string-sql-builder) - 2026-10-06
* [TaskGroup.cancel()で一番早い応答だけを採用する(Python 3.15)](https://kiwamizamurai.github.io/til-with-llm/python/taskgroup-cancel-first-wins) - 2026-10-06
* [add_note()で例外に処理中のファイルと行を書き足す(Python 3.11)](https://kiwamizamurai.github.io/til-with-llm/python/exception-add-note) - 2026-10-06
* [__missing__とformat_map()でテンプレートを何回かに分けて埋める](https://kiwamizamurai.github.io/til-with-llm/python/format-map-missing-partial-template) - 2026-10-05
* [__set_name__で環境変数の設定クラスからキー名の二重書きをなくす](https://kiwamizamurai.github.io/til-with-llm/python/set-name-env-settings) - 2026-10-05
* [__init_subclass__とクラス文のキーワード引数でイベントハンドラーを自動登録する](https://kiwamizamurai.github.io/til-with-llm/python/init-subclass-handler-registry) - 2026-10-05
* [__format__でログにAPIキーを出さないSecret型を作る](https://kiwamizamurai.github.io/til-with-llm/python/secret-format-masking) - 2026-10-05
<!-- index ends -->

## Security Hooks

Claude Code PreToolUse hooks to detect sensitive information. Uses [gitleaks](https://github.com/gitleaks/gitleaks) for API keys/tokens and [RapidFuzz](https://github.com/rapidfuzz/RapidFuzz) for fuzzy matching keywords defined in `blocklist.txt`.
