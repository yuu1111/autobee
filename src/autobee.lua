-- AutoBee メインプログラム
-- Forestry養蜂箱の自動化システム

local component = require("component")
local keyboard = require("keyboard")
local event = require("event")
local term = require("term")

local running = true
local apiaryTimerIDs = {}

print("Starting AutoBee...")

-- モジュール読み込み
dofile("/home/autobee/main.lua")

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

local function removeDevices()
  for _, timerID in pairs(apiaryTimerIDs) do
    event.cancel(timerID)
  end
  apiaryTimerIDs = {}
end

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

local function deviceConnect(_, address)
  addDevice(address)
end

local initDevices

local function deviceDisconnect()
  removeDevices()
  initDevices()
end

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
