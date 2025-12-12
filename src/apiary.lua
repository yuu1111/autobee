-- Apiary: 養蜂箱の管理(Containerを継承)
-- スロット構成: 1=女王/プリンセス, 2=ドローン, 3-9=出力

local queenName = "Forestry:beeQueenGE"
local princessName = "Forestry:beePrincessGE"
local droneName = "Forestry:beeDroneGE"

function Apiary(device, address, apiaryType)
  local self = Container(device)

  function self.getID()
    return address
  end

  function self.getType()
    return apiaryType
  end

  local function getChestSide()
    if apiaryType == "apiary" or apiaryType == "gendustry" then
      return apiaryChestDirection
    elseif apiaryType == "alveary" then
      return alvearyChestDirection
    end
  end

  function self.isPrincessSlotOccupied()
    return self.getItemData(1) ~= nil
  end

  function self.isDroneSlotOccupied()
    return self.getItemData(2) ~= nil
  end

  function self.pushPrincess(slot)
    self.push(getChestSide(), slot, 1, chestSize)
  end

  function self.pullPrincess()
    self.pull(getChestSide(), chestSize, 1, 1)
  end

  function self.pushDrone(slot)
    self.push(getChestSide(), slot, 64, chestSize - 1)
  end

  function self.pullDrone()
    self.pull(getChestSide(), chestSize - 1, 64, 2)
  end

  function self.moveDrone(slot)
    self.pushDrone(slot)
    self.pullDrone()
  end

  function self.movePrincess(slot)
    self.pushPrincess(slot)
    self.pullPrincess()
  end

  function self.isPrincessOrQueen(slot)
    local itemType = self.itemType(slot)
    return itemType == "queen" or itemType == "princess"
  end

  -- 戻り値: "queen", "princess", "drone", false(その他), nil(空)
  function self.itemType(slot)
    local item = self.getItemData(slot)
    if item ~= nil then
      local name = item.name
      if name == queenName then
        return "queen"
      elseif name == princessName then
        return "princess"
      elseif name == droneName then
        return "drone"
      else
        return false
      end
    end
    return nil
  end

  function self.isDrone(slot)
    return self.itemType(slot) == "drone"
  end

  function self.checkInput()
    for _ = 1, 2 do
      if not self.isPrincessSlotOccupied() then
        self.pullPrincess()
      end
      if not self.isDroneSlotOccupied() then
        self.pullDrone()
      end
    end
  end

  function self.checkOutput(firstSlot, lastSlot)
    for slot = firstSlot, lastSlot do
      local itemType = self.itemType(slot)
      if itemType ~= nil then
        if itemType == "princess" then
          if self.isPrincessSlotOccupied() then
            self.push(getChestSide(), slot)
          else
            self.movePrincess(slot)
          end
        elseif itemType == "drone" then
          if self.isDroneSlotOccupied() then
            self.push(getChestSide(), slot)
          else
            self.moveDrone(slot)
          end
        else
          self.push(getChestSide(), slot)
        end
      end
    end
  end

  function self.checkApiary(firstSlot, lastSlot)
    self.checkOutput(firstSlot, lastSlot)
    self.checkInput()
  end

  return self
end
