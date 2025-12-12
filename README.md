# AutoBee

OpenComputers用 Forestry養蜂自動化プログラム

## 概要

AutoBeeはForestry Apiaryを自動化します。プリンセスとドローンの補充、出力アイテムのチェストへの移動を自動で行います。

## インストール

OpenComputersのコンピュータで以下を実行:

```lua
wget https://raw.githubusercontent.com/jetpack-maniac/autobee/master/installAutoBee.lua
installAutoBee
```

または手動で `/home/autobee/` に配置:
- `autobee.lua`
- `autobeeCore.lua`

## 使用方法

```bash
/home/autobee/autobee.lua
```

- **Ctrl+W**: プログラム終了
- **Ctrl+L**: 画面クリア

## 設定

`autobeeCore.lua` を編集:

```lua
chestSize = 27                    -- チェストスロット数
apiaryChestDirection = "up"       -- Apiaryからのチェスト方向
alvearyChestDirection = "south"   -- Alvearyからのチェスト方向
delay = 2                         -- チェック間隔（秒）
```

## 対応機器

- Forestry Apiary
- Forestry Alveary

## 必要Mod

- OpenComputers
- OpenPeripherals
- Forestry

## 注意事項

- チェストの最後の2スロットはプリンセス/ドローン用に予約されます
- 純血種以外のハチを使用するとチェストがすぐに満杯になります

## リンク

- [OpenComputers Forum](https://oc.cil.li/index.php?/topic/913-autobee-automate-your-forestry-bees/)
- [GitHub](https://github.com/jetpack-maniac/autobee)
