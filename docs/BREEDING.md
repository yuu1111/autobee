# AutoBee 品種改良・純血化システム設計

## 目標

指定した種族の純血蜂を自動で作成するシステム。

```
入力: 任意のプリンセス + ドローン
      ↓
   自動養蜂・選別
      ↓
出力: 指定種族の純血蜂
```

## 用語定義

| 用語 | 説明 |
|---|---|
| 種族 (Species) | 蜂の種類（Meadows, Forest, Industrious等） |
| Active遺伝子 | 表現される遺伝子（見た目・能力に反映） |
| Inactive遺伝子 | 潜在的な遺伝子（子孫に遺伝する可能性） |
| 純血 (Pure) | Active と Inactive が同じ種族 |
| 混血 (Hybrid) | Active と Inactive が異なる種族 |
| 変異 (Mutation) | 特定の組み合わせで新種が生まれる |

## 遺伝の仕組み

### 遺伝子の継承

```
親プリンセス: [Active: A] [Inactive: B]
親ドローン:   [Active: C] [Inactive: D]

子供の可能性:
  Active   = A or B (プリンセスから1つ)
  Inactive = C or D (ドローンから1つ)
```

### 純血化の原理

```
目標: Species X の純血

Step 1: X を持つ蜂を集める
  [X/?] + [X/?] → 子供は X を持つ確率が高い

Step 2: 繰り返し選別
  [X/X] が出たら純血完成
  [X/?] は再度養蜂に使用
  [?/?] (X無し) は廃棄
```

## システム設計

### 動作モード

```lua
-- config.lua
breedingMode = "purify"  -- "normal" | "purify" | "mutate"
targetSpecies = "forestry.speciesIndustrious"
```

| モード | 動作 |
|---|---|
| `normal` | 従来動作（単純循環） |
| `purify` | 指定種族の純血化 |
| `mutate` | 変異を狙った交配（将来実装） |

### 必要なチェスト構成

```
                [完成品チェスト]
                      ↑ 純血蜂
┌─────────────────────┴─────────────────────┐
│                                           │
[プリンセス候補] [ドローン候補]              │
       ↓              ↓                     │
       └──────┬───────┘                     │
              ↓                             │
          [Apiary]                          │
              ↓                             │
         遺伝子判定                          │
              ↓                             │
    ┌─────────┼─────────┐                   │
    ↓         ↓         ↓                   │
 [純血]    [混血]    [対象外]               │
    │         │         ↓                   │
    │         │    [廃棄チェスト]           │
    │         ↓                             │
    │    候補チェストへ戻す ─────────────────┘
    ↓
[完成品チェスト]
```

### チェスト方向設定（例）

```lua
-- config.lua 拡張
chestDirections = {
  princessInput = "north",   -- プリンセス候補
  droneInput = "south",      -- ドローン候補
  output = "up",             -- 産物・判定待ち
  finished = "east",         -- 純血完成品
  discard = "west"           -- 廃棄
}
```

## 遺伝子API

### データ構造（予想）

```lua
local item = container.getStackInSlot(slot)

-- 蜂のデータ構造
item = {
  name = "Forestry:beePrincessGE",
  damage = 0,
  count = 1,
  individual = {
    genome = {
      active = {
        species = "forestry.speciesIndustrious",
        -- 他の形質...
      },
      inactive = {
        species = "forestry.speciesUnweary",
        -- 他の形質...
      }
    },
    isAnalyzed = true  -- 分析済みか
  }
}
```

### 必要な関数

```lua
-- genetics.lua (新規モジュール)

---蜂の種族情報を取得する
---@param item table アイテムデータ
---@return string|nil active Active種族
---@return string|nil inactive Inactive種族
function getSpecies(item)
  if item and item.individual and item.individual.genome then
    local genome = item.individual.genome
    return genome.active.species, genome.inactive.species
  end
  return nil, nil
end

---蜂が純血か判定する
---@param item table アイテムデータ
---@return boolean 純血か
function isPure(item)
  local active, inactive = getSpecies(item)
  return active ~= nil and active == inactive
end

---蜂が指定種族を持つか判定する
---@param item table アイテムデータ
---@param targetSpecies string 目標種族
---@return boolean 指定種族を持つか
function hasSpecies(item, targetSpecies)
  local active, inactive = getSpecies(item)
  return active == targetSpecies or inactive == targetSpecies
end

---蜂が指定種族の純血か判定する
---@param item table アイテムデータ
---@param targetSpecies string 目標種族
---@return boolean 指定種族の純血か
function isPureTarget(item, targetSpecies)
  local active, inactive = getSpecies(item)
  return active == targetSpecies and inactive == targetSpecies
end
```

## 選別ロジック

### 出力スロット処理フロー

```lua
function processOutput(slot, targetSpecies)
  local item = getItemData(slot)
  if item == nil then return end

  local itemType = getItemType(item)  -- "princess" | "drone" | other

  if itemType == "princess" or itemType == "drone" then
    if isPureTarget(item, targetSpecies) then
      -- 純血完成 → 完成品チェストへ
      pushToFinished(slot)
    elseif hasSpecies(item, targetSpecies) then
      -- 混血だが目標種族あり → 候補チェストへ戻す
      pushToCandidate(slot, itemType)
    else
      -- 目標種族なし → 廃棄
      pushToDiscard(slot)
    end
  else
    -- 蜂以外 → 産物チェストへ
    pushToOutput(slot)
  end
end
```

### 入力補充ロジック

```lua
function refillInput(targetSpecies)
  -- 優先度: 純血に近い個体を優先
  -- 1. 両方が目標種族の個体
  -- 2. Activeが目標種族の個体
  -- 3. Inactiveが目標種族の個体

  if not isPrincessSlotOccupied() then
    local best = findBestCandidate("princess", targetSpecies)
    if best then pullPrincess(best) end
  end

  if not isDroneSlotOccupied() then
    local best = findBestCandidate("drone", targetSpecies)
    if best then pullDrone(best) end
  end
end
```

## 実装フェーズ

### Phase 1: 遺伝子読み取り検証

```
目標: APIで遺伝子情報が取得できることを確認

作業:
1. OC環境で item.individual.genome の構造を確認
2. getSpecies(), isPure() 関数を実装
3. デバッグ出力で動作確認
```

### Phase 2: 基本選別機能

```
目標: 種族フィルタリングの実装

作業:
1. genetics.lua モジュール作成
2. 出力処理に種族判定を追加
3. 複数チェスト対応（候補/完成/廃棄）
```

### Phase 3: 純血化ロジック

```
目標: 純血判定と優先度付き補充

作業:
1. isPureTarget() による完成判定
2. 候補の優先度計算
3. 最適な親の自動選択
```

### Phase 4: UI・設定

```
目標: ユーザー設定と状態表示

作業:
1. config.lua に品種改良設定を追加
2. 進捗表示（純血率、世代数など）
3. 複数目標種族の対応（オプション）
```

## 未確認事項

実装前に確認が必要:

| 項目 | 確認方法 |
|---|---|
| `item.individual` の存在 | ゲーム内でデバッグ出力 |
| 遺伝子データの構造 | `for k,v in pairs()` で探索 |
| 未分析蜂の扱い | `isAnalyzed` フラグの有無 |
| 種族名の形式 | 実際の文字列を確認 |

### 確認用スクリプト

```lua
-- debug_genetics.lua
local component = require("component")

-- Adapterに接続された養蜂箱を取得
for addr, ctype in component.list() do
  if string.find(ctype, "apiculture") or ctype == "bee_housing" then
    local apiary = component.proxy(addr)
    local item = apiary.getStackInSlot(1)

    if item then
      print("=== Item Data ===")
      for k, v in pairs(item) do
        print(k .. ": " .. tostring(v))
      end

      if item.individual then
        print("=== Individual ===")
        for k, v in pairs(item.individual) do
          print(k .. ": " .. tostring(v))
        end
      end
    end
    break
  end
end
```

## ファイル構成（予定）

```
src/
├── main.lua              # エントリポイント
├── config.lua            # 設定（拡張）
├── inventory.lua         # インベントリ操作
├── apiary.lua            # 養蜂箱クラス（拡張）
├── device.lua            # デバイス管理
├── genetics.lua          # 遺伝子操作（新規）
└── installAutoBee.lua    # インストーラー
```
