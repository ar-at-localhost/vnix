local wezterm = require("wezterm")
local act = wezterm.action

---@type VnixKeyGroup
local common = {
  keys = {
    dashboard = {
      key = "d",
      mods = "LEADER",
      action = act.EmitEvent("vnix:dashboard"),
      description = "Dashboard",
    },
    create = {
      key = "+",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:create"),
      description = "Create new",
    },
    rename = {
      key = "r",
      mods = "LEADER",
      action = wezterm.action_callback(function(win, pane)
        wezterm.emit("vnix:trigger-rename", win, pane)
      end),
      description = "Create new workspace",
    },
    kill = { key = ";", mods = "LEADER", action = act.EmitEvent("vnix:kill"), description = "Kill" },
    persist = {
      key = "p",
      mods = "LEADER",
      action = wezterm.action_callback(function(win, pane)
        wezterm.emit("vnix:persist", win, pane, "secondary")
      end),
    },
    persist_primary = {
      key = "P",
      mods = "LEADER|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        wezterm.emit("vnix:persist", win, pane, "primary")
      end),
    },
  },
  tables = {},
}

return common
