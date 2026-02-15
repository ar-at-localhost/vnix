local wezterm = require("wezterm")
local vnix = wezterm.GLOBAL.vnix
local act = wezterm.action

local M = {
  special_keys = {
    reset_key_tables = {
      key = "Escape",
      action = "PopKeyTable",
      description = "Reset keybindings",
    },
  },
}

-- Defines the internal mapping of actions to their default key assignments.
-- The keys of this table are the internal names for the actions.
function M.get_defaults()
  return {
    navigate = {
      key = "n",
      mods = "LEADER",
      action = act.ActivateKeyTable({
        name = "vnix_navigation",
        one_shot = false,
      }),
      description = "Navigation Mode",
    },

    -- Pane Navigation & Management
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

    close_pane = {
      key = "x",
      mods = "LEADER",
      action = act.CloseCurrentPane({ confirm = true }),
      description = "Close Current Pane",
    },

    -- Tab & Workspace Management
    spawn_tab = {
      key = "w",
      mods = "LEADER",
      action = act.SpawnTab("CurrentPaneDomain"),
      description = "Spawn New Tab",
    },
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

    -- Pane Resizing
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

    -- Plugin-specific Actions
    inspect = {
      key = "i",
      mods = "LEADER",
      action = act.EmitEvent("vnix:inspect"),
      description = "Inspect VNix State",
    },
    dashboard = {
      key = "d",
      mods = "LEADER",
      action = act.EmitEvent("vnix:dashboard"),
      description = "Dashboard",
    },
    debug = {
      key = "d",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:debug"),
      description = "Debugging",
    },
    switch = {
      key = "s",
      mods = "LEADER",
      action = act.EmitEvent("vnix:switch"),
      description = "Switch",
    },
    create = {
      key = "+",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:create"),
      description = "Create new",
    },
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
    kill = { key = ";", mods = "LEADER", action = act.EmitEvent("vnix:kill"), description = "Kill" },
  }
end

-- Generates the final list of keybindings to be applied to the WezTerm config.
function M.get_keybindings(user_keys)
  user_keys = user_keys or {}
  local defaults = M.get_defaults()
  local final_keys = {}

  ---@type VNixKeybindings
  local tracked_keybindings = {}

  -- Merge user-defined keys over the defaults
  for name, key_info in pairs(defaults) do
    local user_override = user_keys[name]
    if user_override then
      key_info.key = user_override.key or key_info.key
      key_info.mods = user_override.mods or key_info.mods
      key_info.description = user_override.description or key_info.description
    end
    defaults[name] = key_info
  end

  -- Build the final list of keybinding tables for WezTerm
  for name, key_info in pairs(defaults) do
    local key_action = key_info.action
    if not key_action then
      -- For keys that don't have a pre-defined action, create a standard pane direction action
      local direction_map = {
        activate_pane_left = "Left",
        activate_pane_right = "Right",
        activate_pane_down = "Down",
        activate_pane_up = "Up",
      }
      if direction_map[name] then
        key_action = act.ActivatePaneDirection(direction_map[name])
      end
    end

    if key_action then
      local key_combo = (key_info.mods or "") .. " | " .. key_info.key
      local description = key_info.description or ""
      local group = key_info.group or ""

      table.insert(
        tracked_keybindings,
        { key = key_combo, description = description, group = group }
      )

      table.insert(
        final_keys,
        { key = key_info.key, mods = key_info.mods, action = key_action, group = group }
      )
    end
  end

  vnix.keybindings = tracked_keybindings
  return final_keys
end

--- @param all_keybindings table
--- Get nav mode key table, which allows navigation around using hjkl/HL/JK
function M.nav_key_table(all_keybindings)
  local nav_key_table = {}
  table.insert(nav_key_table, M.special_keys.reset_key_tables)
  table.insert(nav_key_table, {
    key = "Enter",
    action = M.special_keys.reset_key_tables.action,
    description = M.special_keys.reset_key_tables.description,
  })

  for _, key_info in ipairs(all_keybindings) do
    if key_info.group == "vnix_navigation" then
      table.insert(nav_key_table, {
        key = key_info.key,
        action = key_info.action,
      })
    end
  end

  return nav_key_table
end

--- @param all_keybindings table
--- get key tables
function M.get_key_tables(all_keybindings)
  return {
    vnix_navigation = M.nav_key_table(all_keybindings),
  }
end

return M
