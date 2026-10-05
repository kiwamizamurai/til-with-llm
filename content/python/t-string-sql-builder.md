---
title: "t-string で SQL インジェクションを型で防ぐ(Python 3.14)"
tags:
  - python
---

f-string は便利だが、SQL を組み立てるのに使うと事故が起きる。

```python
name = "x' OR '1'='1"
conn.execute(f"SELECT name FROM users WHERE name = '{name}'").fetchall()
# → [('alice',), ('bob',), ('carol',)]   全件取れてしまう
```

f-string は評価した瞬間にただの `str` になるので、**どこまでが SQL で、どこからが埋め込んだ値なのか**という情報が残らない。だから受け取る側は値をエスケープできない。

3.14 の t-string(PEP 750)は、`f` を `t` に変えるだけで、文字列ではなく `string.templatelib.Template` を返す。これは「固定の文字列部分」と「埋め込んだ値」を**分けたまま**持っている。

```python
name, age = "alice", 20
t = t"name={name!r} age={age:>5} expr={age + 1}"

t.strings  # ('name=', ' age=', ' expr=', '')
t.values   # ('alice', 20, 21)
list(t)
# ['name=', Interpolation('alice', 'name', 'r', ''),
#  ' age=', Interpolation(20, 'age', None, '>5'),
#  ' expr=', Interpolation(21, 'age + 1', None, '')]
```

`Interpolation` は、評価済みの値(`value`)のほかに、元の式の文字列(`expression`)、`!r` などの変換指定(`conversion`)、`:>5` などの書式指定(`format_spec`)を持っている。**`!r` も `:>5` も適用されずに、そのまま渡ってくる**。どう解釈するかは受け取る関数が決める。

## 小さな SQL ビルダーを作る

値を `?` プレースホルダーに置き換え、値そのものは別のリストに分ける関数を書く。`match` で `Interpolation` の種類ごとに振り分けると読みやすい。

```python
import re
import sqlite3
from string.templatelib import Interpolation, Template

_IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def sql(t: Template) -> tuple[str, list[object]]:
    if not isinstance(t, Template):
        raise TypeError(f"expected Template, got {type(t).__name__}")
    parts: list[str] = []
    params: list[object] = []
    for item in t:
        match item:
            case str():                                   # 固定の SQL 部分
                parts.append(item)
            case Interpolation(value=Template() as inner):  # 入れ子の t-string
                q, p = sql(inner)
                parts.append(q)
                params.extend(p)
            case Interpolation(value=value, format_spec="ident"):  # 識別子
                if not isinstance(value, str) or not _IDENT.fullmatch(value):
                    raise ValueError(f"invalid identifier: {value!r}")
                parts.append(f'"{value}"')
            case Interpolation(value=list() | tuple() as values):  # IN 句
                parts.append(", ".join("?" * len(values)))
                params.extend(values)
            case Interpolation(value=value):              # 普通の値
                parts.append("?")
                params.append(value)
    return "".join(parts), params


def execute(conn: sqlite3.Connection, t: Template) -> list[tuple]:
    query, params = sql(t)
    return conn.execute(query, params).fetchall()
```

### 使ってみる

```python
name = "x' OR '1'='1"
sql(t"SELECT name FROM users WHERE name = {name}")
# → ('SELECT name FROM users WHERE name = ?', ["x' OR '1'='1"])
execute(conn, t"SELECT name FROM users WHERE name = {name}")
# → []   ただの文字列として比較されるだけ
```

リストを渡すと、IN 句のプレースホルダーを要素の数だけ展開する。

```python
ids = [1, 3]
sql(t"SELECT name FROM users WHERE id IN ({ids})")
# → ('SELECT name FROM users WHERE id IN (?, ?)', [1, 3])
```

**t-string は入れ子にできる。** 条件を部品として組み立て、別の t-string の中に埋め込める。値は最後まで値として扱われる。

```python
min_age = 18
cond = t"age >= {min_age}"
sql(t"SELECT name FROM users WHERE {cond} ORDER BY {'age':ident}")
# → ('SELECT name FROM users WHERE age >= ? ORDER BY "age"', [18])
```

テーブル名や列名は `?` にできない(プレースホルダーに使えるのは値だけ)。そこで、**書式指定 `:ident` を「これは識別子です」という印として使い**、正規表現で検査してから埋め込む。書式指定に何を書くかは受け取る側が決められる、という t-string の性質を利用している。

```python
table = "users; DROP TABLE users"
sql(t"SELECT * FROM {table:ident}")
# ValueError: invalid identifier: 'users; DROP TABLE users'
```

## 型チェッカーが f-string を弾いてくれる

`execute` の引数を `Template` で型付けしておくと、うっかり f-string を渡したときに型エラーになる。**`t` を `f` に書き間違えたら CI で止まる**。

```console
$ mypy --python-version 3.14 app.py
app.py:5: error: Argument 2 to "execute" has incompatible type "str"; expected "Template"  [arg-type]

$ pyright --pythonversion 3.14 app.py
app.py:5:15 - error: Argument of type "LiteralString" cannot be assigned to parameter "t" of type "Template"
```

## ハマりどころ

- **実行時の型チェックを省くと、f-string が素通りする。** 上のコードの先頭にある `isinstance` の検査を外すと、`str` もループで回せてしまう(1 文字ずつの `str` として `case str():` に入る)。結果、**f-string が渡されても何のエラーも出ずにインジェクションが成立する**。実際に試すと `[('alice',), ('bob',)]` と全件返ってきた。型チェッカーを通さない呼び出し元もありうるので、実行時の検査は必須。
- **`str(t)` は SQL を返さない。** `Template` には「文字列に戻す」決まった方法がなく、`str()` すると `Template(strings=(...), interpolations=(...))` という repr が返る。これは設計上の意図で、文字列にする方法はいつも受け取る側が決める。
- **`Template` と `str` は `+` でつなげない。** `t"a" + "b"` は `TypeError` になる(`t"a" + t"b"` は `Template` になる)。文字列を後から足していくような書き方は、自然と避けられる。
- **値は t-string を書いた時点で評価される。** 遅延評価ではない。ループの中で作れば、そのたびに評価される。
- 反復すると空の文字列は飛ばされる。`t"{a}{b}"` の `strings` は `('', '', '')` だが、`list(t)` には `Interpolation` しか出てこない。

## 実務では

- 自前で SQL を組み立てる小さな関数(社内のバッチ処理、分析用のクエリ)を `Template` しか受け取らない形にしておくと、レビューで「この f-string は安全か」を確かめる手間がなくなる。
- 同じ考え方は、HTML(値を自動でエスケープする)、シェルのコマンド(値を `shlex.quote` する)、ログ(構造化ログで値を別のフィールドに出す)にもそのまま使える。
- ただし、本番で使うなら SQLAlchemy などのクエリビルダーで足りることが多い。t-string が効くのは、**生の SQL を書きたいが安全も欲しい**という間の領域。

## References

- [PEP 750 – Template Strings](https://peps.python.org/pep-0750/)
- [string.templatelib — Python docs](https://docs.python.org/3/library/string.templatelib.html)
- [What's New In Python 3.14 – Template string literals](https://docs.python.org/3/whatsnew/3.14.html)
