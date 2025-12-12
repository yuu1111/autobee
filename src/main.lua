--[[
  main.lua - メインプログラム
  Forestry養蜂箱の自動化システム

  読み込み順:
    1. config.lua (設定)
    2. inventory.lua (インベントリ操作)
    3. apiary.lua (養蜂箱クラス)

  操作:
    Ctrl+W: 終了
    Ctrl+L: 画面クリア
]]

local component = require("component")
local keyboard = require("keyboard")
local event = require("event")
local term = require("term")

local running = true
local apiaryTimerIDs = {}
local basePath = "/home/autobee/"

print("Starting AutoBee...")

-- モジュール読み込み
dofile(basePath .. "config.lua")
dofile(basePath .. "inventory.lua")
dofile(basePath .. "apiary.lua")

---テーブルの要素数を取得する
---@param input table テーブル
---@return number 要素数
local function size(input)
  local count = 0
  for _, _ in pairs(input) do
    count = count + 1
  end
  return count
end

---指定アドレスが養蜂箱コンポーネントか判定する
---@param address string|nil コンポーネントアドレス
---@return boolean 養蜂箱か
local function isApiary(address)
  if address == nil then
    return false
  end
  local deviceType = component.type(address)
  if deviceType == nil then
    return false
  end
  if string.find(deviceType, "bee_housing") then
    return true
  elseif string.find(deviceType, "apiculture") and deviceType:sub(21, 21) == "0" then
    return true
  end
  return false
end

---養蜂箱が接続されているか確認し、なければ終了する
local function peripheralCheck()
  local apiary = nil
  for address, componentType in pairs(component.list()) do
    local isApiaryComponent = (string.find(componentType, "apiculture") and componentType:sub(21, 21) == "0")
      or componentType == "bee_housing"
    if isApiaryComponent then
      apiary = address
      break
    end
  end
  if apiary == nil then
    print("No apiaries found. Closing program.")
    os.exit()
  end
end

---全ての養蜂箱タイマーをキャンセルする
local function removeDevices()
  for _, timerID in pairs(apiaryTimerIDs) do
    event.cancel(timerID)
  end
  apiaryTimerIDs = {}
end

---デバイスを養蜂箱として登録し、タイマーを設定する
---@param address string|nil コンポーネントアドレス
---@return boolean 登録成功したか
local function addDevice(address)
  if address == nil then
    return false
  end
  if isApiary(address) then
    local apiary = Apiary(component.proxy(address), address)
    apiaryTimerIDs[address] = event.timer(delay, function()
      apiary.checkApiary(3, 9)
    end, math.huge)
    return true
  end
  return false
end

---コンポーネント接続時のイベントハンドラ
---@param _ any 未使用
---@param address string コンポーネントアドレス
local function deviceConnect(_, address)
  addDevice(address)
end

local initDevices

---コンポーネント切断時のイベントハンドラ
local function deviceDisconnect()
  removeDevices()
  initDevices()
end

---全デバイスを走査して養蜂箱を登録し、イベントリスナーを設定する
initDevices = function()
  event.ignore("component_available", deviceConnect)
  event.ignore("component_removed", deviceDisconnect)
  local devices = component.list()
  for address, _ in pairs(devices) do
    addDevice(address)
  end
  event.listen("component_added", deviceConnect)
  event.listen("component_removed", deviceDisconnect)
end

---実行状況を表示する
local function printInfo()
  print("AutoBee running.")
  print("Hold Ctrl+W to stop. Hold Ctrl+L to clear terminal.")
  print(size(apiaryTimerIDs) .. " apiaries connected.")
end

peripheralCheck()
if running then
  initDevices()
  printInfo()
end

while running do
  if keyboard.isKeyDown(keyboard.keys.w) and keyboard.isControlDown() then
    event.ignore("component_available", deviceConnect)
    event.ignore("component_removed", deviceDisconnect)
    removeDevices()
    print("AutoBee: Interrupt detected. Closing program.")
    break
  end
  if keyboard.isKeyDown(keyboard.keys.l) and keyboard.isControlDown() then
    term.clear()
    printInfo()
  end
  os.sleep(delay)
end
