---
title: "__format__でログにAPIキーを出さないSecret型を作る"
tags:
  - python
  - data-model
  - security
  - logging
---

`logger.info(f"calling API with {token}")`のようなログを書くと、本番のログにAPIキーがそのまま残る。値を文字列にする経路で必ず伏せ字になる型を作っておくと、うっかり出力しても漏れない。

f-stringの`{x:spec}`の`spec`の部分は、そのまま`x.__format__(spec)`に渡される。書式指定の中身は型が自由に決めてよいので、`{token:last4}`のような独自の指定も作れる。

## 作り方

文字列にする経路は`__format__`(f-stringと`str.format`)、`__str__`(`str()`と`%s`)、`__repr__`(`!r`やコンテナの中、`f"{x=}"`)の3つある。全部ふさぐ。

```python
class Secret:
    __slots__ = ("_value",)

    def __init__(self, value: str) -> None:
        self._value = value

    def __format__(self, spec: str) -> str:
        if spec == "last4":
            return "********" + self._value[-4:]
        if spec == "":
            return "********"
        raise ValueError(f"unknown format spec for Secret: {spec!r}")

    def __repr__(self) -> str:
        return "Secret('********')"

    __str__ = __repr__

    def reveal(self) -> str:
        return self._value
```

本物の値は`reveal()`を明示的に呼んだときだけ取り出せる。HTTPヘッダーに入れるなど、本当に必要な場所でだけ呼ぶ。

## どの経路で伏せられるか

```console
f"{token}"             -> ********
f"{token:last4}"       -> ********abcd
f"{token!s}"           -> Secret('********')
f"{token=}"            -> token=Secret('********')
"%s" % token           -> Secret('********')
"{}".format(token)     -> ********
str(token)             -> Secret('********')
[token]                -> [Secret('********')]
dataclass repr         -> Req(url='https://api', token=Secret('********'))
logging.warning("token=%r", token) -> token=Secret('********')
json.dumps             -> TypeError: Object of type Secret is not JSON serializable
token.reveal()         -> sk-live-1234567890abcd
```

`Secret`を属性に持つdataclassの`repr`も、中で`repr(token)`を呼ぶので伏せ字になる。`json.dumps`は知らない型として例外になるので、APIのレスポンスに紛れ込んだときも気づける。

## ハマりどころ

`__format__`を定義せずに`__str__`だけ定義した場合、`f"{x}"`は`object.__format__`経由で`str(x)`になるので伏せられる。ただし`{x:last4}`のように書式指定を付けると`TypeError: unsupported format string passed to OnlyStr.__format__`になる。空でない書式指定を受け付けるかどうかは、`__format__`を自分で書いて決める必要がある。

上の実装では、知らない書式指定を`ValueError`にしている。`f"{token:>20}"`のような幅の指定も通らない。`format(str(self), spec)`に任せると幅揃えはできるようになるが、`{token:raw}`のような書き間違いが`ValueError`にならず素通りするので、ここでは厳しくした。

`pickle`は伏せ字にならない。`pickle.dumps(token)`の中には生の値がそのまま入る。プロセス間で受け渡したりキャッシュに保存したりする場合は、`__reduce__`で禁止するか、受け渡す前に`reveal()`して扱いを決める。

## References

- [object.__format__ — Python Data Model](https://docs.python.org/3/reference/datamodel.html#object.__format__)
- [Format Specification Mini-Language](https://docs.python.org/3/library/string.html#formatspec)
