-- インベントリ操作

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

function pullItem(container, sourceDirection, fromSlot, amount, destinationSlot)
  if pcall(function()
    container.pullItemIntoSlot(sourceDirection, fromSlot, amount, destinationSlot)
  end) then
    return true
  elseif debugPrints then
    print("AutoBee Error: Failed to pull item")
  end
end

-- Container: インベントリ操作の基本ラッパー
function Container(tileEntity)
  local self = {}

  function self.getItemData(slot)
    return getItemData(tileEntity, slot)
  end

  function self.push(destinationDirection, fromSlot, amount, destinationSlot)
    return pushItem(tileEntity, destinationDirection, fromSlot, amount, destinationSlot)
  end

  function self.pull(sourceDirection, fromSlot, amount, destinationSlot)
    return pullItem(tileEntity, sourceDirection, fromSlot, amount, destinationSlot)
  end

  return self
end
