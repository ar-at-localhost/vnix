local wezterm = require("wezterm")
local act = wezterm.action

---@type VnixKeyGroup
local common = {
  keys = {
    reload = {
      key = "R",
      mods = "LEADER|SHIFT",
      action = act.ReloadConfiguration,
      description = "Reload configurations",
    },

    -- Plugin-specific Actions
    inspect = {
      key = "I",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:inspect"),
      description = "Inspect VNix State",
    },
    debug = {
      key = "D",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:debug"),
      description = "Debugging",
    },
  },
  tables = {},
}

return common
