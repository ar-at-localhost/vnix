local wezterm = require("wezterm")
local act = wezterm.action

---@type VnixKeyGroup
local workspace = {
  keys = {
    create_tab = {
      key = "t",
      mods = "LEADER",
      action = wezterm.action_callback(function(win, pane)
        wezterm.emit("vnix:create", win, pane, "tab")
      end),
      description = "Create new tab",
    },
    kill_tab = {
      key = "'",
      mods = "LEADER",
      action = act.EmitEvent("vnix:kill-tab"),
      description = "Create new workspace",
    },
    swap_tab_right = {
      key = ")",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:swap-tab-right"),
      description = "Swap tab with right tab",
    },
    swap_tab_left = {
      key = "(",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:swap-tab-left"),
      description = "Swap tab with previous tab",
    },
  },
  tables = {},
}

return workspace
