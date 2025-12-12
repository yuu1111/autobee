-- AutoBee コアライブラリ

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

-- モジュール読み込み(依存順)
dofile(basePath .. "inventory.lua")
dofile(basePath .. "apiary.lua")

-- ユーティリティ
function size(input)
  local count = 0
  for _, _ in pairs(input) do
    count = count + 1
  end
  return count
end
