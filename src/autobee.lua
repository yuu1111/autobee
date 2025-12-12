---- AutoBee for OpenComputers ----

local component = require("component")
local keyboard = require("keyboard")
local event = require("event")
local filesystem = require("filesystem")
local internet = require("internet")
local term = require("term")

local running = true
local apiaryTimerIDs = {}

print("Starting AutoBee...")

-- Loads the core library, fetches if missing
local function loadCore()
  local searchPath = "/home/autobee/"
  local library = "autobeeCore.lua"
  local coreURL = "https://raw.githubusercontent.com/jetpack-maniac/autobee/master/src/autobeeCore.lua"

  if not filesystem.exists(searchPath) then
    filesystem.makeDirectory(searchPath)
  end

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

-- looks at a device and determines if it's a valid apiary
local function isApiary(address)
  if address == nil then
    return false
  end
  local deviceType = component.type(address)
  if deviceType == nil then
    return false
  end
  -- 1.10.2/1.11.2 Apiaries
  if string.find(deviceType, "bee_housing") then
    return true
  -- 1.7.10 Apiaries
  elseif string.find(deviceType, "apiculture") and deviceType:sub(21, 21) == "0" then
    return true
  end
  return false
end

-- Peripheral check
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

-- Device Management
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

-- Forward declaration
local initDevices

local function deviceDisconnect()
  removeDevices()
  initDevices()
end

initDevices = function()
  -- Ignore in case the program crashed and listeners are still active
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

----------------------
-- Main
----------------------

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
