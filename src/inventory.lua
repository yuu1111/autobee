--[[
  inventory.lua - インベントリ操作
  OpenPeripherals APIのラッパー関数とContainerクラス

  使用グローバル: debugPrints
  定義グローバル: getItemData, pushItem, pullItem, Container
]]

---指定スロットのアイテム情報を取得する
---@param container table OpenPeripheralsコンテナ
---@param slot number スロット番号
---@return table|nil アイテム情報、失敗時nil
function getItemData(container, slot)
  local itemMeta = nil
  if pcall(function()
    itemMeta = container.getStackInSlot(slot)
  end) then
    return itemMeta
  elseif debugPrints then
    print("AutoBee Error: Failed to get item data from slot " .. slot)
  end
end

---アイテムを指定方向のコンテナに移動する
---@param container table OpenPeripheralsコンテナ
---@param destinationDirection string 移動先の方向
---@param fromSlot number 移動元スロット
---@param amount number|nil 移動数
---@param destinationSlot number|nil 移動先スロット
---@return boolean|nil 成功時true
function pushItem(container, destinationDirection, fromSlot, amount, destinationSlot)
  if
    pcall(function()
      container.pushItemIntoSlot(destinationDirection, fromSlot, amount, destinationSlot)
    end)
  then
    return true
  elseif debugPrints then
    print("AutoBee Error: Failed to push item")
  end
end

---指定方向のコンテナからアイテムを取得する
---@param container table OpenPeripheralsコンテナ
---@param sourceDirection string 取得元の方向
---@param fromSlot number 取得元スロット
---@param amount number|nil 取得数
---@param destinationSlot number|nil 格納先スロット
---@return boolean|nil 成功時true
function pullItem(container, sourceDirection, fromSlot, amount, destinationSlot)
  if pcall(function()
    container.pullItemIntoSlot(sourceDirection, fromSlot, amount, destinationSlot)
  end) then
    return true
  elseif debugPrints then
    print("AutoBee Error: Failed to pull item")
  end
end

---コンテナ操作をラップするクラスを生成する
---@param tileEntity table OpenPeripheralsタイルエンティティ
---@return table Containerインスタンス
function Container(tileEntity)
  local self = {}

  ---指定スロットのアイテム情報を取得する
  ---@param slot number スロット番号
  ---@return table|nil アイテム情報
  function self.getItemData(slot)
    return getItemData(tileEntity, slot)
  end

  ---アイテムを指定方向のコンテナに移動する
  ---@param destinationDirection string 移動先の方向
  ---@param fromSlot number 移動元スロット
  ---@param amount number|nil 移動数
  ---@param destinationSlot number|nil 移動先スロット
  ---@return boolean|nil 成功時true
  function self.push(destinationDirection, fromSlot, amount, destinationSlot)
    return pushItem(tileEntity, destinationDirection, fromSlot, amount, destinationSlot)
  end

  ---指定方向のコンテナからアイテムを取得する
  ---@param sourceDirection string 取得元の方向
  ---@param fromSlot number 取得元スロット
  ---@param amount number|nil 取得数
  ---@param destinationSlot number|nil 格納先スロット
  ---@return boolean|nil 成功時true
  function self.pull(sourceDirection, fromSlot, amount, destinationSlot)
    return pullItem(tileEntity, sourceDirection, fromSlot, amount, destinationSlot)
  end

  return self
end
