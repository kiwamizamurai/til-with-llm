---
title: "add_note()で例外に処理中のファイルと行を書き足す(Python 3.11)"
tags:
  - python
  - python-3-11
  - exceptions
  - logging
  - debugging
---

CSVを読み込むバッチで`ValueError: invalid literal for int() with base 10: 'lots'`とだけ出て落ちると、どのファイルの何行目かがわからない。

例外を捕まえて別の例外を`raise ... from e`で投げ直すと情報は足せるが、例外の型が変わり、トレースバックも2つに分かれて長くなる。3.11で入った`BaseException.add_note()`(PEP 678)を使うと、元の例外の型もトレースバックもそのままで、メモの行だけを足せる。

## 使い方

```python
def load(name: str) -> list[tuple[int, int]]:
    out = []
    for lineno, row in enumerate(csv.DictReader(open(name)), start=2):
        try:
            out.append(parse_row(row))
        except ValueError as e:
            e.add_note(f"file={name} line={lineno} row={row}")
            raise
    return out
```

```console
  File "basic.py", line 7, in parse_row
    return int(row["id"]), int(row["qty"])
                           ~~~^^^^^^^^^^^^
ValueError: invalid literal for int() with base 10: 'lots'
file=orders-2.csv line=3 row={'id': '2', 'qty': 'lots'}
```

メモは例外メッセージの次の行に出る。追加したメモは`e.__notes__`(文字列のリスト)に入っていて、何度でも足せる。

`raise ... from e`との違いを、同じ情報を足した場合で比べた。

| | 外に出る例外の型 | トレースバックの行数 |
|---|---|---|
| `raise RuntimeError(...) from e` | `RuntimeError` | 16行 |
| `e.add_note(...); raise` | `ValueError`のまま | 9行 |

型が変わらないので、呼び出し元の`except ValueError`もそのまま効く。「原因を別の意味の例外に変換したい」なら`from`を使い、「状況を書き足したいだけ」なら`add_note()`を使う、と使い分けられる。

## コンテキストマネージャーにする

`try`と`except`を毎回書くのは面倒なので、小さなヘルパーにしておくと便利だ。入れ子にすると、内側のメモから順に積まれる。

```python
from contextlib import contextmanager


@contextmanager
def note(msg: str):
    try:
        yield
    except Exception as e:
        e.add_note(msg)
        raise


for name, rows in files.items():
    with note(f"file={name}"):
        for lineno, qty in enumerate(rows, start=1):
            with note(f"line={lineno} qty={qty!r}"):
                int(qty)
```

```console
ValueError: invalid literal for int() with base 10: 'lots'
line=2 qty='lots'
file=b.csv
```

## ハマりどころ

`str(e)`にはメモが含まれない。ログを`log.error(f"failed: {e}")`のように書いていると、せっかく足したメモが消える。

```console
str: invalid literal for int() with base 10: 'lots'
ERROR failed: invalid literal for int() with base 10: 'lots'
```

メモまで出すには、`log.exception()`か`exc_info=True`でトレースバックごと出すか、`traceback.format_exception_only(e)`を使う。後者は`["ValueError: ...\n", "file=orders-2.csv line=3\n"]`のように、メモを含んだ行のリストを返す。

もう1つ気をつけたいのは、メモが例外オブジェクトそのものを書き換えることだ。同じ例外インスタンスが何度も投げられる場面では、メモが積み重なる。

```python
fut = executor.submit(boom, 1)
for attempt in range(3):
    try:
        fut.result()          # 毎回同じ例外インスタンスが投げられる
    except ValueError as e:
        e.add_note(f"attempt={attempt}")

fut.exception().__notes__
# ['attempt=0', 'attempt=1', 'attempt=2']
```

asyncioでも、同じタスクを2か所で`await`してそれぞれメモを足すと、`['seen by waiter 1', 'seen by waiter 2']`のように両方のメモが1つの例外に残る。リトライのたびにメモを足すコードや、結果を複数の待ち手で共有するコードでは、メモが重複していないか確かめた方がよい。

そのほかに確かめた挙動は次のとおり。

- `ProcessPoolExecutor`のワーカーで足したメモは、pickleを通っても呼び出し元まで残る。
- `ExceptionGroup`に足したメモは、`split()`や`subgroup()`で分けたあとの両方のグループにコピーされる。
- `add_note()`に文字列以外を渡すと`TypeError`になる。ただし`e.__notes__`に直接代入するとその検査はなく、文字列を代入すると、トレースバックにはそのreprの`'oops'`が1行として出る。

## References

- [PEP 678 – Enriching Exceptions with Notes](https://peps.python.org/pep-0678/)
- [BaseException.add_note — Python docs](https://docs.python.org/3/library/exceptions.html#BaseException.add_note)
- [traceback.format_exception_only — Python docs](https://docs.python.org/3/library/traceback.html#traceback.format_exception_only)
