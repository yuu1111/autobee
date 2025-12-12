--[[
  debug_genetics.lua - 遺伝子API検証スクリプト
  蜂アイテムのデータ構造を調査する

  ダウンロード:
    wget https://raw.githubusercontent.com/yuu1111/autobee/master/debug/debug_genetics.lua

  使用方法:
    1. 養蜂箱のスロット1にプリンセスか女王を入れる
    2. このスクリプトを実行: debug_genetics.lua
    3. 出力されるデータ構造を確認
]]

local component = require("component")

---テーブルの中身を再帰的に表示する
---@param tbl table 表示するテーブル
---@param indent number インデント深さ
---@param maxDepth number 最大深さ
local function printTable(tbl, indent, maxDepth)
  indent = indent or 0
  maxDepth = maxDepth or 5

  if indent > maxDepth then
    print(string.rep("  ", indent) .. "...")
    return
  end

  for k, v in pairs(tbl) do
    local prefix = string.rep("  ", indent)
    if type(v) == "table" then
      print(prefix .. tostring(k) .. ": {")
      printTable(v, indent + 1, maxDepth)
      print(prefix .. "}")
    else
      print(prefix .. tostring(k) .. ": " .. tostring(v) .. " (" .. type(v) .. ")")
    end
  end
end

---養蜂箱を探して返す
---@return table|nil proxy 養蜂箱のプロキシ
---@return string|nil address アドレス
local function findApiary()
  for address, ctype in component.list() do
    if string.find(ctype, "apiculture") or string.find(ctype, "bee_housing") then
      return component.proxy(address), address
    end
  end
  return nil, nil
end

-- メイン処理
print("===========================================")
print("AutoBee Genetics Debug Script")
print("===========================================")
print("")

local apiary, address = findApiary()

if not apiary then
  print("ERROR: 養蜂箱が見つかりません")
  print("AdapterをApiaryに隣接させてください")
  return
end

print("養蜂箱を検出: " .. address)
print("")

-- スロット1のアイテムを取得
local item = apiary.getStackInSlot(1)

if not item then
  print("ERROR: スロット1にアイテムがありません")
  print("プリンセスか女王をスロット1に入れてください")
  return
end

print("=== 基本情報 ===")
print("name: " .. tostring(item.name))
print("label: " .. tostring(item.label))
print("count: " .. tostring(item.count))
print("")

print("=== 全データ構造 ===")
printTable(item, 0, 6)
print("")

-- individual があるか確認
if item.individual then
  print("=== individual 発見 ===")

  if item.individual.genome then
    print("")
    print("=== genome 発見 ===")

    local genome = item.individual.genome

    if genome.active then
      print("")
      print("--- Active 遺伝子 ---")
      if genome.active.species then
        print("species: " .. tostring(genome.active.species))
      end
      printTable(genome.active, 1, 3)
    end

    if genome.inactive then
      print("")
      print("--- Inactive 遺伝子 ---")
      if genome.inactive.species then
        print("species: " .. tostring(genome.inactive.species))
      end
      printTable(genome.inactive, 1, 3)
    end
  else
    print("genome が見つかりません")
    print("individual の内容:")
    printTable(item.individual, 1, 4)
  end

  -- 分析済みか確認
  if item.individual.isAnalyzed ~= nil then
    print("")
    print("isAnalyzed: " .. tostring(item.individual.isAnalyzed))
  end
else
  print("individual が見つかりません")
  print("")
  print("利用可能なキー:")
  for k, _ in pairs(item) do
    print("  - " .. tostring(k))
  end
end

print("")
print("===========================================")
print("デバッグ完了")
print("===========================================")
