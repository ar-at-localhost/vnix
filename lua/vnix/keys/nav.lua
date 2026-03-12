local wezterm = require("wezterm")
local specials = require("vnix.keys.specials")
local act = wezterm.action

---@type VnixKeyGroup
local nav = {
  keys = {
    navigate = {
      key = "n",
      mods = "LEADER",
      action = act.ActivateKeyTable({
        name = "vnix_navigation",
        one_shot = false,
      }),
      description = "Navigation Mode",
    },

    switch = {
      key = "s",
      mods = "LEADER",
      action = act.EmitEvent("vnix:switch"),
      description = "Switch",
    },

    --- Panes ---
    activate_pane_left = {
      key = "h",
      mods = "LEADER",
      action = act.EmitEvent("vnix:nav-pane-left"),
      description = "Focus Left Pane",
      group = "vnix_navigation",
    },
    activate_pane_right = {
      key = "l",
      mods = "LEADER",
      action = act.EmitEvent("vnix:nav-pane-right"),
      description = "Focus Right Pane",
      group = "vnix_navigation",
    },
    activate_pane_down = {
      key = "j",
      mods = "LEADER",
      action = act.EmitEvent("vnix:nav-pane-down"),
      description = "Focus Bottom Pane",
      group = "vnix_navigation",
    },
    activate_pane_up = {
      key = "k",
      mods = "LEADER",
      action = act.EmitEvent("vnix:nav-pane-up"),
      description = "Focus Upper Pane",
      group = "vnix_navigation",
    },

    --- Tabs ---
    activate_tab_prev = {
      key = "H",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:nav-tab-prev"),
      description = "Activate Previous Tab",
      group = "vnix_navigation",
    },
    activate_tab_next = {
      key = "L",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:nav-tab-next"),
      description = "Activate Next Tab",
      group = "vnix_navigation",
    },
    activate_tab_first = {
      key = "0",
      mods = "LEADER",
      action = act.EmitEvent("vnix:nav-tab-first"),
      description = "Activate First Tab",
      group = "vnix_navigation",
    },
    activate_tab_last = {
      key = "$",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:nav-tab-last"),
      description = "Activate Last Tab",
      group = "vnix_navigation",
    },

    --- Workspaces ---
    switch_workspace_prev = {
      key = "J",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:nav-workspace-prev"),
      description = "Switch to Previous Workspace",
      group = "vnix_navigation",
    },
    switch_workspace_next = {
      key = "K",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:nav-workspace-next"),
      description = "Switch to Next Workspace",
      group = "vnix_navigation",
    },
    switch_workspace_first = {
      key = "g",
      mods = "LEADER",
      action = act.EmitEvent("vnix:nav-workspace-first"),
      description = "Switch to First Workspace",
      group = "vnix_navigation",
    },
    switch_workspace_last = {
      key = "G",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:nav-workspace-last"),
      description = "Switch to Last Workspace",
      group = "vnix_navigation",
    },
  },

  tables = {},
}

local free_navigation = {
  specials.keys.reset_key_table,
  {
    key = "Enter",
    action = specials.keys.pop_key_table.action,
    description = specials.keys.pop_key_table.description,
  },
}

for _, key_info in ipairs(nav.keys) do
  if key_info.group == "vnix_navigation" then
    table.insert(free_navigation, {
      key = key_info.key,
      action = key_info.action,
    })
  end
end

nav.tables.free_navigation = free_navigation

return nav
