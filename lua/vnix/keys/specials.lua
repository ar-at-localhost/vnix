local wezterm = require("wezterm")
local act = wezterm.action

---@type VnixKeyGroup
local specials = {
  keys = {
    pop_key_table = {
      key = "Escape",
      action = act.PopKeyTable,
      description = "Reset keybindings",
    },
  },
  tables = {},
}

return specials
