--[[
  apiary.lua - 養蜂箱クラス
  Containerを継承した養蜂箱管理クラス

  スロット構成:
    1: 女王/プリンセス
    2: ドローン
    3-9: 出力

  対応アイテム: GTNH 1.7.10 Forestry
  依存: inventory.lua (Container)
  使用グローバル: Container, chestSize, apiaryChestDirection, alvearyChestDirection
  定義グローバル: Apiary
]]

local queenName = "Forestry:beeQueenGE"
local princessName = "Forestry:beePrincessGE"
local droneName = "Forestry:beeDroneGE"

---養蜂箱を管理するクラスを生成する
---@param device table OpenPeripheralsデバイス
---@param address string コンポーネントアドレス
---@param apiaryType string|nil 養蜂箱タイプ ("apiary"|"alveary"|"gendustry")
---@return table Apiaryインスタンス
function Apiary(device, address, apiaryType)
  local self = Container(device)

  ---コンポーネントアドレスを取得する
  ---@return string コンポーネントアドレス
  function self.getID()
    return address
  end

  ---養蜂箱タイプを取得する
  ---@return string|nil 養蜂箱タイプ
  function self.getType()
    return apiaryType
  end

  ---養蜂箱タイプに応じたチェストの方向を取得する
  ---@return string|nil チェストの方向
  local function getChestSide()
    if apiaryType == "apiary" or apiaryType == "gendustry" then
      return apiaryChestDirection
    elseif apiaryType == "alveary" then
      return alvearyChestDirection
    end
  end

  ---プリンセス/女王スロット(1)が埋まっているか確認する
  ---@return boolean プリンセス/女王スロットが埋まっているか
  function self.isPrincessSlotOccupied()
    return self.getItemData(1) ~= nil
  end

  ---ドローンスロット(2)が埋まっているか確認する
  ---@return boolean ドローンスロットが埋まっているか
  function self.isDroneSlotOccupied()
    return self.getItemData(2) ~= nil
  end

  ---プリンセスを出力スロットからチェストに移動する
  ---@param slot number 出力スロット番号
  function self.pushPrincess(slot)
    self.push(getChestSide(), slot, 1, chestSize)
  end

  ---チェストからプリンセスを入力スロットに移動する
  function self.pullPrincess()
    self.pull(getChestSide(), chestSize, 1, 1)
  end

  ---ドローンを出力スロットからチェストに移動する
  ---@param slot number 出力スロット番号
  function self.pushDrone(slot)
    self.push(getChestSide(), slot, 64, chestSize - 1)
  end

  ---チェストからドローンを入力スロットに移動する
  function self.pullDrone()
    self.pull(getChestSide(), chestSize - 1, 64, 2)
  end

  ---ドローンを出力スロットからチェスト経由で入力スロットに移動する
  ---@param slot number 出力スロット番号
  function self.moveDrone(slot)
    self.pushDrone(slot)
    self.pullDrone()
  end

  ---プリンセスを出力スロットからチェスト経由で入力スロットに移動する
  ---@param slot number 出力スロット番号
  function self.movePrincess(slot)
    self.pushPrincess(slot)
    self.pullPrincess()
  end

  ---指定スロットのアイテムがプリンセスか女王か判定する
  ---@param slot number スロット番号
  ---@return boolean プリンセスか女王か
  function self.isPrincessOrQueen(slot)
    local itemType = self.itemType(slot)
    return itemType == "queen" or itemType == "princess"
  end

  ---指定スロットのアイテムタイプを判定する
  ---@param slot number スロット番号
  ---@return string|boolean|nil "queen"|"princess"|"drone"|false(その他)|nil(空)
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

  ---指定スロットのアイテムがドローンか判定する
  ---@param slot number スロット番号
  ---@return boolean ドローンか
  function self.isDrone(slot)
    return self.itemType(slot) == "drone"
  end

  ---入力スロットにプリンセスとドローンを補充する
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

  ---出力スロットのアイテムを処理する
  ---@param firstSlot number 開始スロット
  ---@param lastSlot number 終了スロット
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

  ---養蜂箱の出力と入力を処理する
  ---@param firstSlot number 開始スロット
  ---@param lastSlot number 終了スロット
  function self.checkApiary(firstSlot, lastSlot)
    self.checkOutput(firstSlot, lastSlot)
    self.checkInput()
  end

  return self
end
