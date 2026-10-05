---
title: "__missing__とformat_map()でテンプレートを何回かに分けて埋める"
tags:
  - python
  - data-model
  - string
---

通知メールの文面で、宛名は今わかるが発送日は後で決まる、ということがある。`str.format()`は足りないキーが1つでもあると`KeyError`になるので、埋められるところだけ先に埋めることができない。

```python
tmpl = "Hello {name}, your order {order_id} ships on {date}"
tmpl.format(name="Alice")
# KeyError: 'order_id'
```

`dict`のサブクラスに`__missing__`を定義すると、存在しないキーを`d[key]`で引いたときの動きを変えられる。`str.format_map()`はキーを`d[key]`で引くので、この2つを組み合わせると足りないところを`{key}`のまま残せる。

## 使い方

```python
class Keep(dict):
    def __missing__(self, key):
        return "{" + key + "}"


step1 = tmpl.format_map(Keep(name="Alice"))
# 'Hello Alice, your order {order_id} ships on {date}'

step1.format_map(Keep(order_id=42, date="10/9"))
# 'Hello Alice, your order 42 ships on 10/9'
```

`format(**d)`ではなく`format_map(d)`を使うのがポイントで、`**`で展開すると普通のdictにコピーされて`__missing__`が効かない。

## __missing__が呼ばれる条件

`__missing__`は`dict.__getitem__`がキーを見つけられなかったときにだけ呼ばれる。`get()`や`in`では呼ばれない。

```python
k = Keep(name="Alice")
k["x"]      # '{x}'
k.get("x")  # None
"x" in k    # False
```

`collections.defaultdict`も同じ仕組みで、`__missing__`の中で値を作って登録している。

## ハマりどころ

残したプレースホルダーに書式指定や属性アクセスが付いていると、そこで失敗する。`__missing__`が返すのはただの文字列なので、その文字列に対して書式指定や属性アクセスが適用されるからだ。

```console
'{name} {date}'       -> 'Alice {date}'
'{name} {price:,}'    -> ValueError Cannot specify ',' with 's'.
'{name} {user.email}' -> AttributeError 'str' object has no attribute 'email'
'{name} {items[0]}'   -> 'Alice {'
'{name!r} {date!r}'   -> "'Alice' '{date}'"
```

`{items[0]}`は例外にならず、`'{items}'`の0文字目の`{`が入る。エラーにならないぶん気づきにくい。`!r`の場合は文字列`{date}`の`repr`が入るので、引用符で囲まれた`'{date}'`が残る。2回目に埋めると`'10/9'`になり、結果的に引用符付きの値になる。書式指定や`!r`を使うテンプレートは、この方法では分割して埋められないと考えた方がよい。

単純な置き換えだけでよければ、標準ライブラリの`string.Template.safe_substitute()`でも同じことができる。こちらは`$name`の形式で、足りないキーをそのまま残す。

```python
string.Template("Hello $name, ships on $date").safe_substitute(name="Alice")
# 'Hello Alice, ships on $date'
```

## 関連

- [[secret-format-masking|__format__でログにAPIキーを出さないSecret型を作る]]: 書式指定が`__format__`に渡る仕組み

## References

- [object.__missing__ — Python Data Model](https://docs.python.org/3/reference/datamodel.html#object.__missing__)
- [str.format_map — Python docs](https://docs.python.org/3/library/stdtypes.html#str.format_map)
- [string.Template.safe_substitute — Python docs](https://docs.python.org/3/library/string.html#string.Template.safe_substitute)
