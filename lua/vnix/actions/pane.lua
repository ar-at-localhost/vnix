local wezterm = require("wezterm")

local function resize(win, pane, dir)
  win:perform_action(wezterm.action.AdjustPaneSize({ dir, 5 }), pane)
  wezterm.emit("vnix:state-update", "effective")
end

wezterm.on("vnix:resize_right", function(win, pane)
  resize(win, pane, "Right")
end)

wezterm.on("vnix:resize_down", function(win, pane)
  resize(win, pane, "Down")
end)

wezterm.on("vnix:resize_left", function(win, pane)
  resize(win, pane, "Left")
end)

wezterm.on("vnix:resize_up", function(win, pane)
  resize(win, pane, "Up")
end)
