-- AutoBee Installer for OpenComputers
local urls = {
  autobee = "https://raw.githubusercontent.com/jetpack-maniac/autobee/master/autobee.lua",
  autobeeCore = "https://raw.githubusercontent.com/jetpack-maniac/autobee/master/autobeeCore.lua",
}

-- OpenComputers
local filesystem = require("filesystem")
local internet = require("internet")

local installLocation = "/home/autobee/"

print("AutoBee Installer for OpenComputers")
print("Installing to: " .. installLocation)

if not filesystem.exists(installLocation) then
  filesystem.makeDirectory(installLocation)
end

for filename, url in pairs(urls) do
  filename = filename .. ".lua"
  print("Downloading " .. filename .. "...")
  local file = io.open(installLocation .. filename, "w")
  if file then
    for chunk in internet.request(url) do
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
