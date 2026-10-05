---
paths:
  - "content/**/*.md"
---

# TIL を書くときは yomiyasu スキルで推敲する

`content/` 配下の TIL を書く・書き直すときは、**`yomiyasu` スキルで推敲する**。

- スキルはプラグインとして参照している(`.claude/settings.json`、`yomiyasu@yomiyasu`、上流 `nanaism/yomiyasu` の `v1.0.2` に固定、自動更新なし)。Skill ツールでは `yomiyasu:yomiyasu` として呼ぶ。更新するときは `ref` を上げる前に上流の差分を確認する。
- 呼べないとき(プラグインが未取得など)は、上流の同じタグを取得して `skills/yomiyasu/SKILL.md` の手順どおりに進める。
- ドメインは `tech`。
- 最優先は「意味の保持」と「足さない」。主張・比重・言い切りの強さ・文の働きを変えない。文体(である調 / です・ます調)は元の文のまま保つ。
- 推敲の対象は地の文だけ。コードブロック、コマンドの出力、front matter、References のリンクは書き換えない。
- 同梱の `scripts/yomiyasu_lint.py` をかけ、直すのは最大 2 回まで(警告を消すためだけの言い換えはしない)。
- 書き直したら、元の文と書き直した文をスクラッチパッドに保存して `scripts/yomiyasu_diff.py` で比べ、修正は 1 回だけ行う。中間ファイルはリポジトリに残さない。
