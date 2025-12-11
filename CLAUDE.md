# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

AutoBeeはMinecraft Forestryモジュールの養蜂自動化システム。ComputerCraft (CC)とOpenComputers (OC)の両プラットフォームに対応したLuaプログラム。

## アーキテクチャ

```
autobeeCore.lua          # 共通ロジック（Container/Apiaryクラス、ユーティリティ）
├── autobee_cc.lua       # ComputerCraft用実装
├── autobee_oc.lua       # OpenComputers用実装
└── installAutoBee.lua   # インストーラー
```

### コア設計

**peripheralVersion**: APIの抽象化層。Plethora（1.10.2+）とOpenPeripherals（1.7.10）を検出・切り替え

**Container クラス**: インベントリ操作のラッパー（getItemData, push, pull）

**Apiary クラス**: Containerを継承。apiary/gendustry/alvearyの3タイプに対応
- スロット管理: 入力スロット（1=女王/プリンセス, 2=ドローン）、出力スロット（タイプにより3-9または7-15）
- チェスト連携: `chestSize`の末尾2スロット（プリンセス用・ドローン用）を予約領域として使用

### プラットフォーム差異

| 機能 | ComputerCraft | OpenComputers |
|------|--------------|---------------|
| イベントループ | `parallel.waitForAny` | `event.timer` |
| キー入力 | `os.pullEvent("key_up")` | `keyboard.isKeyDown()` |
| 周辺機器 | `peripheral.getNames()` | `component.list()` |
| 内部移動 | `push("self", ...)` | チェスト経由 |

## 設定値（autobeeCore.lua）

- `chestSize`: 出力チェストのスロット数（デフォルト: 27）
- `apiaryChestDirection`/`alvearyChestDirection`: チェストの方向
- `delay`: チェック間隔（秒）
- `debugPrints`: デバッグ出力の有効化

## 対応機器

- Forestry Apiary: スロット3-9
- Gendustry Industrial Apiary: スロット7-15
- Forestry Alveary: スロット3-9

## 命名規則

アイテム識別用の名前配列（queenNames, princessNames, droneNames）はMinecraftバージョン間の互換性のため複数の形式を保持。

## 開発環境

### EmmyLua (型補完)

`.luadocs/` にGTNH-OC-Lua-Documentationをsubmoduleとして配置。VS Code設定済み。

```
.luadocs/lua/
├── libs/        # OC標準ライブラリ (component, event, filesystem等)
├── components/  # コンポーネント定義 (transposer, beekeeper等)
└── type-definitions/
```

**関連コンポーネント**:
- `beekeeper`: GTNH専用の養蜂アダプター
- `transposer`: インベントリ転送（getStackInSlot, transferItem）
- `inventory-controller`: ロボット用インベントリ操作
