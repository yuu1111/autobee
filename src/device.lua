--[[
  device.lua - デバイス管理
  養蜂箱デバイスの検出・登録・タイマー管理

  使用グローバル: Apiary, delay
  定義グローバル: DeviceManager
]]

local component = require("component")
local event = require("event")

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

---デバイス管理クラスを生成する
---@return table DeviceManagerインスタンス
function DeviceManager()
  local self = {}
  local timerIDs = {}

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

  ---デバイスを養蜂箱として登録し、タイマーを設定する
  ---@param address string|nil コンポーネントアドレス
  ---@return boolean 登録成功したか
  function self.add(address)
    if address == nil then
      return false
    end
    if isApiary(address) then
      local apiary = Apiary(component.proxy(address), address)
      timerIDs[address] = event.timer(delay, function()
        apiary.checkApiary(3, 9)
      end, math.huge)
      return true
    end
    return false
  end

  ---全ての養蜂箱タイマーをキャンセルする
  function self.removeAll()
    for _, timerID in pairs(timerIDs) do
      event.cancel(timerID)
    end
    timerIDs = {}
  end

  ---登録されている養蜂箱の数を取得する
  ---@return number 養蜂箱の数
  function self.count()
    return size(timerIDs)
  end

  ---養蜂箱が接続されているか確認する
  ---@return boolean 養蜂箱が存在するか
  function self.hasApiaries()
    for address, componentType in pairs(component.list()) do
      local isApiaryComponent = (string.find(componentType, "apiculture") and componentType:sub(21, 21) == "0")
        or componentType == "bee_housing"
      if isApiaryComponent then
        return true
      end
    end
    return false
  end

  ---全デバイスを走査して養蜂箱を登録する
  function self.scanAll()
    local devices = component.list()
    for address, _ in pairs(devices) do
      self.add(address)
    end
  end

  return self
end
