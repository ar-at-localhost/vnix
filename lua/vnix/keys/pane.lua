local wezterm = require("wezterm")
local act = wezterm.action

---@type VnixKeyGroup
local pane = {
  keys = {
    close_pane = {
      key = "x",
      mods = "LEADER",
      action = act.CloseCurrentPane({ confirm = true }),
      description = "Close Current Pane",
    },

    --- Split ---
    split_bottom = {
      key = "-",
      mods = "LEADER",
      action = act.EmitEvent("vnix:split_pane_bottom"),
      description = "Split Bottom",
    },
    split_right = {
      key = "|",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:split_pane_right"),
      description = "Split Pane Right",
    },

    --- Resize ---
    resize_left = {
      key = "<",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:resize_left"),
      description = "Resize Left",
    },
    resize_down = {
      key = "v",
      mods = "LEADER",
      action = act.EmitEvent("vnix:resize_down"),
      description = "Resize Down",
    },
    resize_up = {
      key = "^",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:resize_up"),
      description = "Resize Up",
    },
    resize_right = {
      key = ">",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:resize_right"),
      description = "Resize Right",
    },
  },
  tables = {},
}

return pane
