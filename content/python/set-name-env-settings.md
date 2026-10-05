---
title: "__set_name__で環境変数の設定クラスからキー名の二重書きをなくす"
tags:
  - python
  - data-model
  - descriptor
  - configuration
---

設定を環境変数から読むとき、`database_url = os.environ["DATABASE_URL"]`のように同じ名前を2回書き、型の変換も場所ごとにばらばらに書いていることが多い。pydantic-settingsを入れるほどではない小さなスクリプトやバッチで、これを短く書きたい。

デスクリプタに`__set_name__`を定義すると、クラスを作るときに「自分がどの属性名に代入されたか」を受け取れる(3.6から)。属性名から環境変数のキーを決めれば、キー名を書かずに済む。

## 作り方

```python
import os
from collections.abc import Callable


class Env:
    def __init__(self, cast: Callable[[str], object] = str, *, default: object = None) -> None:
        self.cast = cast
        self.default = default

    def __set_name__(self, owner: type, name: str) -> None:
        self.key = name.upper()
        if "_envs" not in owner.__dict__:
            owner._envs = []
        owner._envs.append(self)

    def __get__(self, obj: object, owner: type | None = None):
        if obj is None:
            return self  # クラスから触ったときはデスクリプタ自身を返す
        raw = os.environ.get(self.key)
        if raw is None:
            if self.default is None:
                raise RuntimeError(f"env {self.key} is not set")
            return self.default
        return self.cast(raw)


class Settings:
    database_url = Env()
    timeout = Env(int, default=30)
    debug = Env(lambda s: s == "1", default=False)

    @classmethod
    def missing(cls) -> list[str]:
        return [e.key for e in cls._envs if e.default is None and e.key not in os.environ]
```

`__set_name__`の中で、自分を持ち主のクラスの`_envs`に登録している。これで、起動時に必須の環境変数がそろっているかをまとめて確かめられる。

```console
missing: ['DATABASE_URL']
# DATABASE_URL=postgres://db TIMEOUT=5 を設定したあと
postgres://db 5 False | missing: []
```

`timeout`は`int`に変換されて`5`になり、未設定の`debug`はデフォルトの`False`になる。値は属性を読むたびに環境変数から読み直すので、テストで`os.environ`を書き換えるとすぐに反映される。

## __set_name__が呼ばれるタイミング

`__set_name__`が呼ばれるのは、`class`文が実行されて`type.__new__`がクラスを作るときの1回だけだ。クラス本体の名前空間にある値のうち`__set_name__`を持つものを集めて、属性名と一緒に呼ぶ。そのため、あとから代入したデスクリプタには呼ばれない。

```python
Settings.region = Env()
Settings().region
# AttributeError: 'Env' object has no attribute 'key'
```

あとから足す必要があるなら、`Settings.region.__set_name__(Settings, "region")`のように自分で呼ぶ。

同じインスタンスを2つの名前に代入すると、`__set_name__`が2回呼ばれて後の名前で上書きされる。

```python
shared = Env()
class Twice:
    a = shared
    b = shared
shared.key  # 'B'
```

## ハマりどころ

`Env`は`__get__`だけを持つ非データデスクリプタなので、インスタンスに同じ名前で代入すると、インスタンスの`__dict__`が優先される。

```python
s.timeout = 99
s.timeout  # 99(以後は環境変数を読まない)
```

テストで値を差し替えるのには便利だが、設定を読み取り専用にしたいなら`__set__`も定義して`AttributeError`を投げる。`__set__`を持つデータデスクリプタは、インスタンスの`__dict__`より優先される。

変換の失敗は、起動時ではなく属性を読んだときに起きる。`TIMEOUT=abc`なら、`s.timeout`を読んだ時点で`ValueError: invalid literal for int() with base 10: 'abc'`になる。起動時に検出したいなら、`missing()`と同じように`_envs`を回して全部一度読んでおく。

## References

- [object.__set_name__ — Python Data Model](https://docs.python.org/3/reference/datamodel.html#object.__set_name__)
- [Descriptor Guide — Python HOWTO](https://docs.python.org/3/howto/descriptor.html)
