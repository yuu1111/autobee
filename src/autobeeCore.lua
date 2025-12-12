--- Configuration

-- The max size of the output inventory
chestSize = 27

-- chest direction relative to apiary/alveary
apiaryChestDirection = "up"
alvearyChestDirection = "south"

-- how long the computer will wait in seconds before checking the apiaries
delay = 2

-- debug printing for functions
debugPrints = false

--- End of Configuration

local queenNames = { "beeQueenGE", "forestry:beeQueenGE", "forestry:bee_queen_ge" }
local princessNames = { "beePrincessGE", "forestry:beePrincessGE", "forestry:bee_princess_ge" }
local droneNames = { "beeDroneGE", "forestry:beeDroneGE", "forestry:bee_drone_ge" }

--------------------------------------------------------------------------------
-- Misc Functions

-- returns the size of a data structure
function size(input)
  local count = 0
  for _, _ in pairs(input) do
    count = count + 1
  end
  return count
end

-- searches a sample table and returns true if any element matches the criterion
function matchAny(criterion, sample)
  for i = 1, #sample do
    if criterion == sample[i] then
      return true
    end
  end
  return false
end

-- Dependency Check for OpenPeripherals
function dependencyCheck(device)
  if device == nil then
    return nil
  end
  if device.canBreed == nil then
    error("This game server lacks OpenPeripherals mod which is required for AutoBee.")
  end
  return true
end

-- Peripheral Interfaces (OpenPeripherals)

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

-- End of Misc Functions
--------------------------------------------------------------------------------
-- Container class

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

--------------------------------------------------------------------------------
-- Apiary class

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

  -- Moves drone from output into input (via chest)
  function self.moveDrone(slot)
    self.pushDrone(slot)
    self.pullDrone()
  end

  -- Moves princess from output into input (via chest)
  function self.movePrincess(slot)
    self.pushPrincess(slot)
    self.pullPrincess()
  end

  function self.isPrincessOrQueen(slot)
    local itemType = self.itemType(slot)
    return itemType == "queen" or itemType == "princess"
  end

  function self.itemType(slot)
    local item = self.getItemData(slot)
    if item ~= nil then
      local name = item.name
      if matchAny(name, queenNames) then
        return "queen"
      end
      if matchAny(name, princessNames) then
        return "princess"
      end
      if matchAny(name, droneNames) then
        return "drone"
      end
      return false
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

-- End Apiary class
--------------------------------------------------------------------------------
