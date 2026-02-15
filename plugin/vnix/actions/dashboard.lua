local wezterm = require("wezterm")
local rpc = require("vnix.utils.rpc")

wezterm.on("vnix:dashboard", function(win, pane)
  rpc.dispatch(win, pane, {
    id = 0,
    type = "launch",
    return_to = 0,
    data = nil,
  })
end)
