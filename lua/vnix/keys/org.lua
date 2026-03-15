local wezterm = require("wezterm")
local tbl = require("common.tbl")
local specials = require("vnix.keys.specials")
local act = wezterm.action

---@type VnixKeyGroup
local org = {
  keys = {
    reload = {
      key = "o",
      mods = "LEADER",
      action = act.ActivateKeyTable({
        name = "org",
      }),
      description = "Org",
    },
  },
  tables = {
    org = tbl.deep_merge(specials.keys, {
      tasks = {
        key = "t",
        mods = "",
        action = act.EmitEvent("vnix:org-tasks"),
        description = "Org: Tasks",
      },
    }),
  },
}

return org
