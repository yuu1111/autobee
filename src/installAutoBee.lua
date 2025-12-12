-- AutoBee インストーラー (OpenComputers用)
-- GitHubからautobeeファイルをダウンロードしてインストールする

local baseURL = "https://raw.githubusercontent.com/yuu1111/autobee/master/src/"
local files = { "autobee.lua", "autobeeCore.lua", "inventory.lua", "apiary.lua", "config.lua" }

-- OpenComputers ライブラリ読み込み
local filesystem = require("filesystem")
local internet = require("internet")

-- インストール先ディレクトリ
local installLocation = "/home/autobee/"

print("AutoBee Installer for OpenComputers")
print("Installing to: " .. installLocation)

-- インストール先ディレクトリがなければ作成
if not filesystem.exists(installLocation) then
  filesystem.makeDirectory(installLocation)
end

-- 各ファイルをダウンロード
for _, filename in ipairs(files) do
  print("Downloading " .. filename .. "...")
  local file = io.open(installLocation .. filename, "w")
  if file then
    -- チャンク単位でダウンロードして書き込み
    for chunk in internet.request(baseURL .. filename) do
      file:write(chunk)
      file:flush()
    end
    file:close()
    print("  OK: " .. installLocation .. filename)
  else
    print("  ERROR: Could not create " .. filename)
  end
end

print("")
print("Install complete!")
print("Run: /home/autobee/autobee.lua")
