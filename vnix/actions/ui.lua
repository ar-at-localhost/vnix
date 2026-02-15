local wezterm = require("wezterm")
local rpc = require("vnix.rpc")
local fs = require("vnix.fs")

wezterm.on("user-var-changed", function(win, pane, name, value)
  local common = require("common")
  if name == common.VNIX_USER_VAR_NAME then
    wezterm.emit("vnix:ui-resp", win, pane, value)
  end
end)

---Event: UI Response
---@param win Window
---@param pane Pane
---@param resp string
wezterm.on("vnix:ui-resp", function(win, pane, resp)
  pcall(function()
    rpc.parse(win, pane, resp)
  end)
end)

---Event: UI Response
---@param args UIMessageReqBase
wezterm.on("vnix:ui-req", function(args)
  local vnix = wezterm.GLOBAL.vnix
  fs.write_json(string.format("%s/req.json", vnix.vnix_dir), args)
end)
