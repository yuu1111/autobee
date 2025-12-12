-- AutoBee メインプログラム (OpenComputers用)
-- Forestry養蜂箱の自動化システム

-- OpenComputers ライブラリ読み込み
local component = require("component")
local keyboard = require("keyboard")
local event = require("event")
local filesystem = require("filesystem")
local internet = require("internet")
local term = require("term")

-- 状態変数
local running = true
local apiaryTimerIDs = {} -- 養蜂箱ごとのタイマーID

print("Starting AutoBee...")

-- コアライブラリを読み込む（なければGitHubから取得）
local function loadCore()
  local searchPath = "/home/autobee/"
  local library = "autobeeCore.lua"
  local coreURL = "https://raw.githubusercontent.com/jetpack-maniac/autobee/master/src/autobeeCore.lua"

  -- ディレクトリがなければ作成
  if not filesystem.exists(searchPath) then
    filesystem.makeDirectory(searchPath)
  end

  -- ライブラリが存在すれば読み込み、なければダウンロード
  if filesystem.exists(searchPath .. library) then
    dofile(searchPath .. library)
    print("Loaded AutoBee Core")
  else
    print("Missing AutoBee Core, fetching from Github...")
    local file = io.open(searchPath .. library, "w")
    if file then
      for chunk in internet.request(coreURL) do
        file:write(chunk)
        file:flush()
      end
      file:close()
      dofile(searchPath .. library)
      print("Fetched and loaded AutoBee Core")
    else
      error("Could not create autobeeCore.lua")
    end
  end
end

-- デバイスが養蜂箱かどうか判定
local function isApiary(address)
  if address == nil then
    return false
  end
  local deviceType = component.type(address)
  if deviceType == nil then
    return false
  end
  -- 1.10.2/1.11.2 養蜂箱
  if string.find(deviceType, "bee_housing") then
    return true
  -- 1.7.10 養蜂箱
  elseif string.find(deviceType, "apiculture") and deviceType:sub(21, 21) == "0" then
    return true
  end
  return false
end

-- 周辺機器チェック（養蜂箱の存在確認）
local function peripheralCheck()
  loadCore()
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
  else
    dependencyCheck(component.proxy(apiary))
  end
end

--------------------------------------------------------------------------------
-- デバイス管理
--------------------------------------------------------------------------------

-- 全デバイスのタイマーを削除
local function removeDevices()
  for _, timerID in pairs(apiaryTimerIDs) do
    event.cancel(timerID)
  end
  apiaryTimerIDs = {}
end

-- デバイスを追加（タイマー登録）
local function addDevice(address)
  if address == nil then
    return false
  end
  if isApiary(address) then
    local apiary = Apiary(component.proxy(address), address)
    -- 定期的にcheckApiaryを実行するタイマーを設定
    apiaryTimerIDs[address] = event.timer(delay, function()
      apiary.checkApiary(3, 9)
    end, math.huge)
    return true
  end
  return false
end

-- デバイス接続時のコールバック
local function deviceConnect(_, address)
  addDevice(address)
end

-- 前方宣言
local initDevices

-- デバイス切断時のコールバック
local function deviceDisconnect()
  removeDevices()
  initDevices()
end

-- デバイス初期化（全養蜂箱を登録）
initDevices = function()
  -- クラッシュ時に残ったリスナーを削除
  event.ignore("component_available", deviceConnect)
  event.ignore("component_removed", deviceDisconnect)
  -- 全デバイスを走査して養蜂箱を追加
  local devices = component.list()
  for address, _ in pairs(devices) do
    addDevice(address)
  end
  -- イベントリスナー登録
  event.listen("component_added", deviceConnect)
  event.listen("component_removed", deviceDisconnect)
end

-- 情報表示
local function printInfo()
  print("AutoBee running.")
  print("Hold Ctrl+W to stop. Hold Ctrl+L to clear terminal.")
  print(size(apiaryTimerIDs) .. " apiaries connected.")
end

--------------------------------------------------------------------------------
-- メインループ
--------------------------------------------------------------------------------

peripheralCheck()
if running then
  initDevices()
  printInfo()
end

while running do
  -- Ctrl+W で終了
  if keyboard.isKeyDown(keyboard.keys.w) and keyboard.isControlDown() then
    event.ignore("component_available", deviceConnect)
    event.ignore("component_removed", deviceDisconnect)
    removeDevices()
    print("AutoBee: Interrupt detected. Closing program.")
    break
  end
  -- Ctrl+L で画面クリア
  if keyboard.isKeyDown(keyboard.keys.l) and keyboard.isControlDown() then
    term.clear()
    printInfo()
  end
  os.sleep(delay)
end
