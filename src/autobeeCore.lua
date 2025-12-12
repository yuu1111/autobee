-- AutoBee コアライブラリ
-- Container/Apiaryクラスとユーティリティ関数を提供

--------------------------------------------------------------------------------
-- 設定
--------------------------------------------------------------------------------

-- 出力チェストのスロット数
chestSize = 27

-- 養蜂箱からのチェスト方向
apiaryChestDirection = "up"
alvearyChestDirection = "south"

-- チェック間隔（秒）
delay = 2

-- デバッグ出力
debugPrints = false

--------------------------------------------------------------------------------
-- アイテム名定義（Minecraftバージョン間の互換性用）
--------------------------------------------------------------------------------

local queenNames = { "beeQueenGE", "forestry:beeQueenGE", "forestry:bee_queen_ge" }
local princessNames = { "beePrincessGE", "forestry:beePrincessGE", "forestry:bee_princess_ge" }
local droneNames = { "beeDroneGE", "forestry:beeDroneGE", "forestry:bee_drone_ge" }

--------------------------------------------------------------------------------
-- ユーティリティ関数
--------------------------------------------------------------------------------

-- テーブルの要素数を返す
function size(input)
  local count = 0
  for _, _ in pairs(input) do
    count = count + 1
  end
  return count
end

-- 配列内に一致する要素があればtrueを返す
function matchAny(criterion, sample)
  for i = 1, #sample do
    if criterion == sample[i] then
      return true
    end
  end
  return false
end

-- OpenPeripheralsの依存関係チェック
function dependencyCheck(device)
  if device == nil then
    return nil
  end
  if device.canBreed == nil then
    error("This game server lacks OpenPeripherals mod which is required for AutoBee.")
  end
  return true
end

--------------------------------------------------------------------------------
-- OpenPeripherals インターフェース
--------------------------------------------------------------------------------

-- 指定スロットのアイテム情報を取得
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

-- アイテムをプッシュ（別インベントリへ移動）
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

-- アイテムをプル（別インベントリから取得）
function pullItem(container, sourceDirection, fromSlot, amount, destinationSlot)
  if pcall(function()
    container.pullItemIntoSlot(sourceDirection, fromSlot, amount, destinationSlot)
  end) then
    return true
  elseif debugPrints then
    print("AutoBee Error: Failed to pull item")
  end
end

--------------------------------------------------------------------------------
-- Containerクラス
-- インベントリ操作の基本ラッパー
--------------------------------------------------------------------------------

function Container(tileEntity)
  local self = {}

  -- スロットのアイテム情報を取得
  function self.getItemData(slot)
    return getItemData(tileEntity, slot)
  end

  -- アイテムをプッシュ
  function self.push(destinationDirection, fromSlot, amount, destinationSlot)
    return pushItem(tileEntity, destinationDirection, fromSlot, amount, destinationSlot)
  end

  -- アイテムをプル
  function self.pull(sourceDirection, fromSlot, amount, destinationSlot)
    return pullItem(tileEntity, sourceDirection, fromSlot, amount, destinationSlot)
  end

  return self
end

--------------------------------------------------------------------------------
-- Apiaryクラス
-- 養蜂箱の管理（Containerを継承）
-- スロット構成: 1=女王/プリンセス, 2=ドローン, 3-9=出力
--------------------------------------------------------------------------------

function Apiary(device, address, apiaryType)
  local self = Container(device)

  -- 養蜂箱のアドレスを取得
  function self.getID()
    return address
  end

  -- 養蜂箱のタイプを取得
  function self.getType()
    return apiaryType
  end

  -- チェストの方向を取得（タイプにより異なる）
  local function getChestSide()
    if apiaryType == "apiary" or apiaryType == "gendustry" then
      return apiaryChestDirection
    elseif apiaryType == "alveary" then
      return alvearyChestDirection
    end
  end

  -- プリンセス/女王スロット（1）が埋まっているか
  function self.isPrincessSlotOccupied()
    return self.getItemData(1) ~= nil
  end

  -- ドローンスロット（2）が埋まっているか
  function self.isDroneSlotOccupied()
    return self.getItemData(2) ~= nil
  end

  -- プリンセスをチェストへプッシュ（最後のスロット）
  function self.pushPrincess(slot)
    self.push(getChestSide(), slot, 1, chestSize)
  end

  -- プリンセスをチェストからプル
  function self.pullPrincess()
    self.pull(getChestSide(), chestSize, 1, 1)
  end

  -- ドローンをチェストへプッシュ（最後から2番目のスロット）
  function self.pushDrone(slot)
    self.push(getChestSide(), slot, 64, chestSize - 1)
  end

  -- ドローンをチェストからプル
  function self.pullDrone()
    self.pull(getChestSide(), chestSize - 1, 64, 2)
  end

  -- ドローンを出力→入力へ移動（チェスト経由）
  function self.moveDrone(slot)
    self.pushDrone(slot)
    self.pullDrone()
  end

  -- プリンセスを出力→入力へ移動（チェスト経由）
  function self.movePrincess(slot)
    self.pushPrincess(slot)
    self.pullPrincess()
  end

  -- 指定スロットがプリンセスか女王か判定
  function self.isPrincessOrQueen(slot)
    local itemType = self.itemType(slot)
    return itemType == "queen" or itemType == "princess"
  end

  -- 指定スロットのアイテムタイプを判定
  -- 戻り値: "queen", "princess", "drone", false（その他）, nil（空）
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

  -- 指定スロットがドローンか判定
  function self.isDrone(slot)
    return self.itemType(slot) == "drone"
  end

  -- 入力スロットをチェック（空なら補充）
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

  -- 出力スロットをチェック（アイテムを適切に処理）
  function self.checkOutput(firstSlot, lastSlot)
    for slot = firstSlot, lastSlot do
      local itemType = self.itemType(slot)
      if itemType ~= nil then
        if itemType == "princess" then
          -- プリンセス: 入力が空なら移動、埋まっていればチェストへ
          if self.isPrincessSlotOccupied() then
            self.push(getChestSide(), slot)
          else
            self.movePrincess(slot)
          end
        elseif itemType == "drone" then
          -- ドローン: 入力が空なら移動、埋まっていればチェストへ
          if self.isDroneSlotOccupied() then
            self.push(getChestSide(), slot)
          else
            self.moveDrone(slot)
          end
        else
          -- その他（蜂蜜など）: チェストへ
          self.push(getChestSide(), slot)
        end
      end
    end
  end

  -- 養蜂箱をチェック（出力処理→入力補充）
  function self.checkApiary(firstSlot, lastSlot)
    self.checkOutput(firstSlot, lastSlot)
    self.checkInput()
  end

  return self
end
