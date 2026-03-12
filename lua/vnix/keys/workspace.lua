local wezterm = require("wezterm")
local act = wezterm.action

---@type VnixKeyGroup
local workspace = {
  keys = {
    create_workspace = {
      key = "w",
      mods = "LEADER",
      action = wezterm.action_callback(function(win, pane)
        wezterm.emit("vnix:create", win, pane, "workspace")
      end),
      description = "Create new workspace",
    },
    kill_workspace = {
      key = "\"",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:kill-workspace"),
      description = "Create new workspace",
    },
  },
  tables = {},
}

return workspace
