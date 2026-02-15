local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local rpc = require("vnix.utils.rpc")
local fs = require("vnix.utils.fs")

---Event: UI Response
---@param win Window
---@param pane Pane
---@param resp string
wezterm.on("vnix:ui-resp", function(win, pane, resp)
  pcall(function()
    log.log("INFO", string.format("Response arrived: <%q>", resp))
    rpc.parse(win, pane, resp)
  end)
end)

---Event: UI Response
---@param args UIMessageReqBase
wezterm.on("vnix:ui-req", function(args)
  local vnix = wezterm.GLOBAL.vnix
  fs.write_json(string.format("%s/req.json", vnix.vnix_dir), args)
end)
