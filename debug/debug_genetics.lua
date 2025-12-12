--[[
  debug_genetics.lua - 遺伝子API検証スクリプト
  蜂アイテムのデータ構造を調査する

  ダウンロード:
    wget https://raw.githubusercontent.com/yuu1111/autobee/master/debug/debug_genetics.lua

  使用方法:
    1. 養蜂箱のスロット1にプリンセスか女王を入れる
    2. このスクリプトを実行: debug_genetics.lua
    3. 結果は /tmp/genetics_out.txt に保存される
    4. pastebin put /tmp/genetics_out.txt でアップロード
]]

local component = require("component")

-- 出力ファイル
local outputFile = io.open("/tmp/genetics_out.txt", "w")

---画面とファイル両方に出力する
---@param text string 出力テキスト
local function output(text)
  print(text)
  if outputFile then
    outputFile:write(text .. "\n")
  end
end

---テーブルの中身を再帰的に表示する
---@param tbl table 表示するテーブル
---@param indent number インデント深さ
---@param maxDepth number 最大深さ
local function outputTable(tbl, indent, maxDepth)
  indent = indent or 0
  maxDepth = maxDepth or 5

  if indent > maxDepth then
    output(string.rep("  ", indent) .. "...")
    return
  end

  for k, v in pairs(tbl) do
    local prefix = string.rep("  ", indent)
    if type(v) == "table" then
      output(prefix .. tostring(k) .. ": {")
      outputTable(v, indent + 1, maxDepth)
      output(prefix .. "}")
    else
      output(prefix .. tostring(k) .. ": " .. tostring(v) .. " (" .. type(v) .. ")")
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
output("===========================================")
output("AutoBee Genetics Debug Script")
output("===========================================")
output("")

local apiary, address = findApiary()

if not apiary then
  output("ERROR: 養蜂箱が見つかりません")
  output("AdapterをApiaryに隣接させてください")
  if outputFile then outputFile:close() end
  return
end

output("養蜂箱を検出: " .. address)
output("")

-- スロット1のアイテムを取得
local item = apiary.getStackInSlot(1)

if not item then
  output("ERROR: スロット1にアイテムがありません")
  output("プリンセスか女王をスロット1に入れてください")
  if outputFile then outputFile:close() end
  return
end

output("=== 基本情報 ===")
output("name: " .. tostring(item.name))
output("label: " .. tostring(item.label))
output("count: " .. tostring(item.count))
output("")

output("=== 全データ構造 ===")
outputTable(item, 0, 6)
output("")

-- individual があるか確認
if item.individual then
  output("=== individual 発見 ===")

  if item.individual.genome then
    output("")
    output("=== genome 発見 ===")

    local genome = item.individual.genome

    if genome.active then
      output("")
      output("--- Active 遺伝子 ---")
      if genome.active.species then
        output("species: " .. tostring(genome.active.species))
      end
      outputTable(genome.active, 1, 3)
    end

    if genome.inactive then
      output("")
      output("--- Inactive 遺伝子 ---")
      if genome.inactive.species then
        output("species: " .. tostring(genome.inactive.species))
      end
      outputTable(genome.inactive, 1, 3)
    end
  else
    output("genome が見つかりません")
    output("individual の内容:")
    outputTable(item.individual, 1, 4)
  end

  -- 分析済みか確認
  if item.individual.isAnalyzed ~= nil then
    output("")
    output("isAnalyzed: " .. tostring(item.individual.isAnalyzed))
  end
else
  output("individual が見つかりません")
  output("")
  output("利用可能なキー:")
  for k, _ in pairs(item) do
    output("  - " .. tostring(k))
  end
end

output("")
output("===========================================")
output("デバッグ完了 - 結果は /tmp/genetics_out.txt")
output("===========================================")

-- ファイルを閉じる
if outputFile then outputFile:close() end
