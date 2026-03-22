local wezterm = require("wezterm")
local rpc = require("vnix.rpc")

wezterm.on("vnix:inspect", function(win, pane)
  rpc.dispatch(win, pane, {
    id = 0,
    type = "inspect",
    workspace = "",
    return_to = 0,
    data = nil,
  })
end)
