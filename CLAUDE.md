# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

AutoBeeはMinecraft Forestryモジュールの養蜂自動化システム。OpenComputers専用のLuaプログラム。

## アーキテクチャ

```
autobee.lua           # メインプログラム（OC用）
autobeeCore.lua       # 共通ロジック（Container/Apiaryクラス）
installAutoBee.lua    # インストーラー
```

### コア設計

**Container クラス**: インベントリ操作のラッパー（getItemData, push, pull）

**Apiary クラス**: Containerを継承。apiary/gendustry/alvearyの3タイプに対応
- スロット管理: 入力スロット（1=女王/プリンセス, 2=ドローン）、出力スロット（タイプにより3-9）
- チェスト連携: `chestSize`の末尾2スロット（プリンセス用・ドローン用）を予約領域として使用

### OC API使用

- `component.list()` / `component.proxy()`: 周辺機器アクセス
- `event.timer()`: 定期実行
- `keyboard.isKeyDown()`: キー入力検出

## 設定値（autobeeCore.lua）

- `chestSize`: 出力チェストのスロット数（デフォルト: 27）
- `apiaryChestDirection`/`alvearyChestDirection`: チェストの方向
- `delay`: チェック間隔（秒）
- `debugPrints`: デバッグ出力の有効化

## 対応機器

- Forestry Apiary: スロット3-9
- Forestry Alveary: スロット3-9

## 開発環境

### Lint/Format

```bash
selene *.lua      # Linter
stylua *.lua      # Formatter
stylua --check *.lua
```

### EmmyLua (型補完)

`.luadocs/` にGTNH-OC-Lua-Documentationをsubmoduleとして配置。

```
.luadocs/lua/
├── libs/        # OC標準ライブラリ (component, event, filesystem等)
├── components/  # コンポーネント定義 (transposer, beekeeper等)
└── type-definitions/
```
