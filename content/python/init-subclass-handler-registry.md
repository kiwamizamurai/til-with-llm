---
title: "__init_subclass__とクラス文のキーワード引数でイベントハンドラーを自動登録する"
tags:
  - python
  - data-model
  - class
  - design-pattern
---

Webhookのイベント名と処理の対応表を手で管理していると、ハンドラーを足したのに表に登録し忘れたり、同じイベントを2つのクラスで処理していたりする。クラスを定義しただけで対応表に載り、二重登録はその場でエラーにしたい。

`class Foo(Base, event="order.paid")`のように、クラス文の基底クラスの後ろにはキーワード引数を書ける。この引数は、基底クラスの`__init_subclass__`に渡される(3.6から)。メタクラスもデコレーターも使わずに、サブクラスの定義に割り込める。

## 作り方

```python
class Handler:
    registry: dict[str, type["Handler"]] = {}

    def __init_subclass__(cls, *, event: str | None = None, **kwargs) -> None:
        super().__init_subclass__(**kwargs)
        if event is None:      # 共通処理だけの中間クラスは登録しない
            return
        if (prev := Handler.registry.get(event)) is not None:
            raise TypeError(f"{event!r} already handled by {prev.__qualname__}")
        Handler.registry[event] = cls

    def handle(self, payload: dict) -> str:
        raise NotImplementedError


class OrderHandler(Handler):
    def order_id(self, payload: dict) -> int:
        return payload["id"]


class OrderCreated(OrderHandler, event="order.created"):
    def handle(self, payload: dict) -> str:
        return f"created {self.order_id(payload)}"


class OrderPaid(OrderHandler, event="order.paid"):
    def handle(self, payload: dict) -> str:
        return f"paid {self.order_id(payload)}"


def dispatch(event: str, payload: dict) -> str:
    return Handler.registry[event]().handle(payload)
```

```console
sorted(Handler.registry)            -> ['order.created', 'order.paid']
dispatch("order.paid", {"id": 1})   -> 'paid 1'
```

`__init_subclass__`は、`@classmethod`を付けなくても暗黙にクラスメソッドとして扱われる。`cls`には今作られたサブクラスが入る。

二重登録は、クラスを定義した時点で`TypeError`になる。

```python
class Dup(OrderHandler, event="order.paid"): ...
# TypeError: 'order.paid' already handled by OrderPaid
```

`event`を必須の引数にすれば、書き忘れも検出できる。ただしその場合は`OrderHandler`のような中間クラスも書けなくなるので、上の例では省略可能にして「`None`なら登録しない」としている。

## 呼ばれる順番

`class`文が実行されると、`type.__new__`がクラスを作ったあと、属性の`__set_name__`を呼び、そのあとで親クラスの`__init_subclass__`を呼ぶ。`__init_subclass__`の中では、クラスの属性はもう全部そろっていて、デスクリプタの名前も決まっている。`handle`が定義されているかをここで確かめることもできる。

渡したキーワード引数は`__init_subclass__`に渡るだけで、クラスの属性にはならない(`OrderPaid.event`は存在しない)。あとから参照したいなら、`__init_subclass__`の中で`cls.event = event`のように自分で保存する。

`super().__init_subclass__(**kwargs)`は省略しない方がよい。多重継承で別の基底クラスも`__init_subclass__`を持っている場合、ここで呼ばないとそちらが実行されない。

## ハマりどころ

登録はクラスの定義が実行されたときに起きるので、ハンドラーを書いたモジュールが`import`されていないと登録されない。ハンドラーを置いたパッケージを起動時に全部`import`しておく必要がある。lazy importで遅延させると、使うまで読み込まれないので登録されないままになる([[lazy-imports-cli-startup|lazy importでCLIの起動を速くする]]の「importするだけで登録するプラグイン」と同じ問題)。

モジュールを再読み込みすると、同じクラスがもう一度定義されて二重登録のエラーになる。

```console
importlib.reload(handlers_refund)
# TypeError: 'order.refunded' already handled by Refund
```

開発サーバーの自動リロードや、テストで同じモジュールを読み直す場合に起きる。同じ`__qualname__`と`__module__`からの再登録は上書きを許す、テストの前に`registry`を空にする、などの逃げ道を用意しておく。

## 関連

- [[set-name-env-settings|__set_name__で環境変数の設定クラスからキー名の二重書きをなくす]]: `__init_subclass__`より先に呼ばれる`__set_name__`の使い道

## References

- [object.__init_subclass__ — Python Data Model](https://docs.python.org/3/reference/datamodel.html#object.__init_subclass__)
- [Creating the class object — Python Data Model](https://docs.python.org/3/reference/datamodel.html#class-object-creation)
- [PEP 487 – Simpler customisation of class creation](https://peps.python.org/pep-0487/)
