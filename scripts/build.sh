#!/usr/bin/env bash
# Quartz を取得して content/ をビルドする。
# 使い方: scripts/build.sh            -> ./public にビルド
#         scripts/build.sh --serve    -> http://localhost:8080 でプレビュー
set -euo pipefail

QUARTZ_VERSION="v4.5.2"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUARTZ_DIR="$ROOT/.quartz"

if [ "$(git -C "$QUARTZ_DIR" describe --tags 2>/dev/null || true)" != "$QUARTZ_VERSION" ]; then
  rm -rf "$QUARTZ_DIR"
  git clone --quiet --depth 1 --branch "$QUARTZ_VERSION" https://github.com/jackyzha0/quartz.git "$QUARTZ_DIR"
fi

cp "$ROOT/site/quartz.config.ts" "$ROOT/site/quartz.layout.ts" "$QUARTZ_DIR/"

cd "$QUARTZ_DIR"
npm ci --silent
# content は repo 側を直接指定する（git 履歴から作成日・更新日を取るため）
npx quartz build -d "$ROOT/content" -o "$ROOT/public" "$@"
