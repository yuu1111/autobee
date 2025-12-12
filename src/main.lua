--[[
  main.lua - メインプログラム
  Forestry養蜂箱の自動化システム

  読み込み順:
    1. config.lua (設定)
    2. inventory.lua (インベントリ操作)
    3. apiary.lua (養蜂箱クラス)
    4. device.lua (デバイス管理)

  操作:
    Ctrl+W: 終了
    Ctrl+L: 画面クリア
]]

local keyboard = require("keyboard")
local event = require("event")
local term = require("term")

local running = true
local basePath = "/home/autobee/"

print("Starting AutoBee...")

-- モジュール読み込み
dofile(basePath .. "config.lua")
dofile(basePath .. "inventory.lua")
dofile(basePath .. "apiary.lua")
dofile(basePath .. "device.lua")

-- デバイスマネージャーを初期化
local deviceManager = DeviceManager()

---養蜂箱が接続されているか確認し、なければ終了する
local function peripheralCheck()
  if not deviceManager.hasApiaries() then
    print("No apiaries found. Closing program.")
    os.exit()
  end
end

---コンポーネント接続時のイベントハンドラ
---@param _ any 未使用
---@param address string コンポーネントアドレス
local function deviceConnect(_, address)
  deviceManager.add(address)
end

---コンポーネント切断時のイベントハンドラ
---デバイスを再スキャンして登録し直す
local function deviceDisconnect()
  deviceManager.removeAll()
  deviceManager.scanAll()
end

---イベントリスナーを設定する
local function setupEventListeners()
  event.listen("component_added", deviceConnect)
  event.listen("component_removed", deviceDisconnect)
end

---イベントリスナーを解除する
local function removeEventListeners()
  event.ignore("component_added", deviceConnect)
  event.ignore("component_removed", deviceDisconnect)
end

---実行状況を表示する
local function printInfo()
  print("AutoBee running.")
  print("Hold Ctrl+W to stop. Hold Ctrl+L to clear terminal.")
  print(deviceManager.count() .. " apiaries connected.")
end

-- 初期化
peripheralCheck()
if running then
  deviceManager.scanAll()
  setupEventListeners()
  printInfo()
end

-- メインループ
while running do
  if keyboard.isKeyDown(keyboard.keys.w) and keyboard.isControlDown() then
    removeEventListeners()
    deviceManager.removeAll()
    print("AutoBee: Interrupt detected. Closing program.")
    break
  end
  if keyboard.isKeyDown(keyboard.keys.l) and keyboard.isControlDown() then
    term.clear()
    printInfo()
  end
  os.sleep(delay)
end
