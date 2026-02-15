local wezterm = require("wezterm")
local common = require("vnix-common")

wezterm.on("user-var-changed", function(win, pane, name, value)
  if name == common.VNIX_USER_VAR_NAME then
    wezterm.emit("vnix:ui-resp", win, pane, value)
  end
end)
