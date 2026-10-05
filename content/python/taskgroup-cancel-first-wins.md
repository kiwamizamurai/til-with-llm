---
title: "TaskGroup.cancel()で一番早い応答だけを採用する(Python 3.15)"
tags:
  - python
  - python-3-15
  - asyncio
  - concurrency
---

複数のAPIやミラーに同じ問い合わせを同時に投げて、最初に返ってきた答えだけを使いたいことがある。残りのリクエストは、答えが出た時点で止めたい。

`asyncio.TaskGroup`(3.11)は「全部終わるまで待つ」か「どれかが失敗したら全部止める」しかできなかった。正常に終わったのに残りを止める手段がなかったので、わざと例外を投げて止めるしかなかった。

## これまでの書き方

専用の例外を投げてグループを失敗させ、外側の`except*`で握りつぶす。

```python
import asyncio


class FoundIt(Exception):
    pass


async def first_of(*jobs: tuple[str, float]) -> str:
    winner: str | None = None

    async def run(region: str, delay: float) -> None:
        nonlocal winner
        winner = await fetch(region, delay)
        raise FoundIt  # 答えが出たので、わざと失敗させて残りを止める

    try:
        async with asyncio.TaskGroup() as tg:
            for region, delay in jobs:
                tg.create_task(run(region, delay))
    except* FoundIt:
        pass
    assert winner is not None
    return winner
```

動くが、成功したのに例外で表すのは不自然だ。`except*`の中で本物のエラーと混ざらないように気を配る必要もある。

## 3.15の書き方

3.15で`TaskGroup.cancel()`が入った。呼ぶと、グループ内のまだ終わっていないタスクと、`async with`の本体がキャンセルされる。そして`async with`は`CancelledError`を出さずに普通に抜ける。

```python
async def first_of(*jobs: tuple[str, float]) -> str:
    winner: str | None = None
    async with asyncio.TaskGroup() as tg:

        async def run(region: str, delay: float) -> None:
            nonlocal winner
            result = await fetch(region, delay)
            if winner is None:
                winner = result
                tg.cancel()

        for region, delay in jobs:
            tg.create_task(run(region, delay))
    assert winner is not None
    return winner
```

`fetch`に`finally`を書いて、どのタスクがキャンセルされたかを出してみる。

```console
$ python3.15 new.py
  osaka: finally (cancelled=False)
  us: finally (cancelled=True)
  tokyo: finally (cancelled=True)
result from osaka 0.10s
```

一番早いosaka(0.1秒)の答えが出た時点で、tokyo(0.3秒)とus(0.5秒)はキャンセルされ、全体が0.10秒で返る。キャンセルされた側の`finally`もきちんと実行されるので、接続を閉じるなどの後片付けはこれまでどおり書ける。

## 失敗するタスクがあるとき

上のコードは、どれか1つが例外を出すとグループ全体が失敗する。tokyoが先に`ConnectionError`で落ちると、後から成功するosakaの答えを待たずに全部止まる。

```console
naive: (ConnectionError('tokyo is down'),)
```

「最初に成功した答え」が欲しいなら、各タスクの中で例外を受け止めておく。全部失敗したときだけ、まとめて投げる。

```python
async def first_success(*jobs: tuple[str, float, bool]) -> str:
    winner: str | None = None
    errors: list[Exception] = []
    async with asyncio.TaskGroup() as tg:

        async def run(region: str, delay: float, fail: bool) -> None:
            nonlocal winner
            try:
                result = await fetch(region, delay, fail)
            except ConnectionError as e:
                errors.append(e)
                return
            if winner is None:
                winner = result
                tg.cancel()

        for job in jobs:
            tg.create_task(run(*job))
    if winner is None:
        raise ExceptionGroup("all failed", errors)
    return winner
```

```console
result from osaka
all failed: (ConnectionError('a is down'), ConnectionError('b is down'))
```

## ハマりどころ

`cancel()`は本体もキャンセルするので、本体で`cancel()`を呼んだあとの処理は、次の`await`までしか進まない。

```python
async with asyncio.TaskGroup() as tg:
    tg.create_task(sleeper(10))
    tg.cancel()
    print("A")              # 出る(まだawaitしていない)
    await asyncio.sleep(0)
    print("B")              # 出ない(ここでキャンセルされる)
print("C")                  # 出る(async withは普通に抜ける)
```

`cancel()`のあとに`create_task()`を呼ぶと`RuntimeError: TaskGroup <TaskGroup cancelling> is shutting down`になる。本体の中で起きた場合は、さらに`ExceptionGroup`に包まれて外に出る。

そのほかに確かめた挙動は次のとおり。

- 外からのキャンセルは区別される。`asyncio.timeout()`の時間切れは`TimeoutError`として、外側のタスクの`cancel()`は`CancelledError`として、これまでどおり外に出る。例外を出さずに抜けるのは`tg.cancel()`を呼んだときだけ。
- キャンセルされたタスクが`finally`の中で例外を出すと、その例外は`ExceptionGroup`で外に出る。後片付けの失敗は握りつぶされない。
- `async with`に入る前に`cancel()`を呼んでおくと、入った直後にキャンセルされる。`TaskGroup`を先に作って別の関数に渡し、渡した側から中身をまとめて止められるようにする使い方を想定している。
- 何度呼んでもよく、`async with`を抜けたあとに呼んでも何も起きない。

## 関連

- [[exception-add-note|add_note()で例外に処理中のファイルと行を書き足す]]: `ExceptionGroup`に入った例外や、同じタスクを複数の場所で`await`したときのメモの扱い

## References

- [asyncio.TaskGroup.cancel — Python 3.15 docs](https://docs.python.org/3.15/library/asyncio-task.html#asyncio.TaskGroup.cancel)
- [What's New In Python 3.15 – asyncio](https://docs.python.org/3.15/whatsnew/3.15.html)
- [gh-127214: Add TaskGroup.cancel()](https://github.com/python/cpython/issues/127214)
