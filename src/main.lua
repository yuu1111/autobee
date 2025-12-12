--[[
  main.lua - モジュールローダー
  設定とモジュールを読み込む

  読み込み順:
    1. config.lua (設定)
    2. inventory.lua (インベントリ操作)
    3. apiary.lua (養蜂箱クラス)

  定義グローバル: size
]]

local filesystem = require("filesystem")
local basePath = "/home/autobee/"

-- 設定読み込み
local configPath = basePath .. "config.lua"
if filesystem.exists(configPath) then
  dofile(configPath)
else
  chestSize = 27
  apiaryChestDirection = "up"
  alvearyChestDirection = "south"
  delay = 2
  debugPrints = false
end

-- モジュール読み込み
dofile(basePath .. "inventory.lua")
dofile(basePath .. "apiary.lua")

---テーブルの要素数を取得する
---@param input table テーブル
---@return number 要素数
function size(input)
  local count = 0
  for _, _ in pairs(input) do
    count = count + 1
  end
  return count
end
