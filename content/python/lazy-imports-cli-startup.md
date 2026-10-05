---
title: "lazy importでCLIの起動を速くする(Python 3.15)"
tags:
  - python
  - python-3-15
  - import
  - performance
  - cli
---

pandasを使うCLIで`tool version`を実行すると、バージョンを表示するだけなのに0.3秒ほど待たされる。ファイルの先頭にある`import pandas`が、使わないサブコマンドでも毎回実行されるからだ。

これまでは`import`を関数の中に移して回避していたが、依存関係がファイルのあちこちに散らばって読みにくくなる。3.15で入ったlazy import(PEP 810)を使うと、`import`はファイルの先頭に書いたまま、読み込みを初めて使う時点まで遅らせられる。

## 使い方

`import`の前に`lazy`を付けるだけでよい。

```python
import argparse

lazy import pandas as pd


def report(path: str) -> None:
    df = pd.read_csv(path)  # ここで初めてpandasが読み込まれる
    print(df.describe())


def main() -> None:
    parser = argparse.ArgumentParser(prog="tool")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("version")
    r = sub.add_parser("report")
    r.add_argument("path")
    args = parser.parse_args()
    if args.cmd == "version":
        print("tool 1.0")
    else:
        report(args.path)


main()
```

`tool version`の起動時間を7回ずつ測った中央値は次のとおり(pandas 3.0.6)。

| | `tool version`の起動時間 |
|---|---|
| `import pandas as pd` | 322ms |
| `lazy import pandas as pd` | 39ms |

`-X importtime`で見ると、pandasの読み込みだけで約245msかかっていた。lazy版では`version`の実行中にpandasが一度も読み込まれない。

`lazy from decimal import Decimal`のように`from`の形でも使える。`lazy`はソフトキーワードなので、`lazy = 1`のような既存の変数名はそのまま使える。

## 中身はプロキシオブジェクト

`lazy import`した名前には、最初は`types.LazyImportType`のプロキシが入っている。初めて属性にアクセスした時点で本物のモジュールが読み込まれ、名前が差し替わる。

```python
lazy import json

type(globals()["json"]).__name__  # 'lazy_import'
"json" in sys.modules             # False
json.dumps({})
type(globals()["json"]).__name__  # 'module'
"json" in sys.modules             # True
```

## 読み込みの失敗は使うときに出る

存在しないモジュールを`lazy import`しても、その行ではエラーにならない。初めて使った時点で例外になり、トレースバックには`import`した行と使った行の両方が出る。

```console
started
Traceback (most recent call last):
  File "missing.py", line 1, in <module>
    lazy import not_installed_pkg
ImportError: lazy import of 'not_installed_pkg' raised an exception during resolution

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "missing.py", line 10, in <module>
    run()
  File "missing.py", line 7, in run
    return not_installed_pkg.do()
           ^^^^^^^^^^^^^^^^^
ModuleNotFoundError: No module named 'not_installed_pkg'
```

起動時に依存関係の欠けを検出していたCLIでは、その確認が実際に使う場面まで遅れることになる。

## 書ける場所の制限

`lazy import`を書けるのはモジュールの最上位だけで、次の場所では`SyntaxError`になる。

```console
SyntaxError: lazy import not allowed inside functions
SyntaxError: lazy import not allowed inside classes
SyntaxError: lazy import not allowed inside try/except blocks
SyntaxError: lazy from ... import * is not allowed
```

`try`の中で書けないので、`try: import ujson as json / except ImportError: import json`のような「あれば使う」書き方には使えない。

## ハマりどころ: importするだけで登録するプラグイン

一番気をつけたいのは、`import`したときの副作用に頼っているコードだ。デコレーターで自分をレジストリに登録するプラグインは、`import`されないと登録されない。

```python
# app/plugins/csv_export.py
from app.registry import register

@register("csv")
def export_csv(rows): ...
```

```python
import app.plugins.csv_export  # 登録のためだけのimport
from app.registry import HANDLERS
print(sorted(HANDLERS))
```

```console
$ python3.15 reg_eager.py
['csv']
$ python3.15 reg_lazy.py                 # lazy import app.plugins.csv_export にした版
[]
$ python3.15 -X lazy_imports=all reg_eager.py
[]
```

名前を一度も使わないので読み込みが起きず、エラーも出ないままハンドラーが空になる。`-X lazy_imports=all`(または環境変数`PYTHON_LAZY_IMPORTS=all`)で全体をまとめて遅延させたときも同じことが起きる。

全体を遅延させたいときは、`sys.set_lazy_imports_filter()`で対象を絞れる。フィルターは`(importing, imported, fromlist)`を受け取り、`True`を返したものだけが遅延される。

```python
import sys

def only_app(importing, imported, fromlist):
    return imported.startswith("app.")

sys.set_lazy_imports_filter(only_app)
sys.set_lazy_imports("all")

import app.plugins.csv_export  # 遅延される
import json                    # すぐ読み込まれる
```

## 型注釈だけで使う名前

3.14から型注釈の評価が遅延されるようになったので、型注釈にしか出てこない名前は読み込まれない。

```python
lazy from pandas import DataFrame

def summarize(df: DataFrame) -> int: ...
# この時点で "pandas" in sys.modules は False
```

ただし、`annotationlib.get_annotations(summarize)`のように型注釈を実行時に読むと、その時点でpandasが読み込まれる。型注釈を実行時に読むライブラリと組み合わせると、そのライブラリが読んだ時点で読み込まれる。

## 3.14以前と両立させる

`lazy import`は3.14では`SyntaxError`になるので、そのファイルは3.14で動かない。両方で動かしたい場合は、モジュールに`__lazy_modules__`を定義する。ここに名前を挙げたモジュールは、普通の`import`文でも3.15では遅延される。3.14ではただの変数として無視される。

```python
__lazy_modules__ = ["json"]
import json
```

```console
3.14.8    json loaded right after import: True
3.15.0rc3 json loaded right after import: False
```

## References

- [PEP 810 – Explicit lazy imports](https://peps.python.org/pep-0810/)
- [What's New In Python 3.15 – Explicit lazy imports](https://docs.python.org/3.15/whatsnew/3.15.html)
