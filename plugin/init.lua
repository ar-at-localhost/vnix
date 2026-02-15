local wezterm = require("wezterm")

local function findPluginPackagePath(vnixPluginPath)
  local sep = package.config:sub(1, 1) == "\\" and "\\" or "/"
  for _, v in ipairs(wezterm.plugin.list()) do
    if v.url == vnixPluginPath then
      local base = v.plugin_dir
      return table.concat({
        -- core plugin files
        base
          .. sep
          .. "plugin"
          .. sep
          .. "?.lua",
        base .. sep .. "plugin" .. sep .. "?/init.lua",

        -- deeper nesting for subdirectories
        base
          .. sep
          .. "plugin"
          .. sep
          .. "?/?.lua",
        base .. sep .. "plugin" .. sep .. "?/?/init.lua",

        -- secondary lua files
        base
          .. sep
          .. "plugin"
          .. sep
          .. "lua"
          .. sep
          .. "?.lua",
        base .. sep .. "plugin" .. sep .. "lua" .. sep .. "?/init.lua",

        -- test helpers (so you can require them from specs)
        base
          .. sep
          .. "plugin"
          .. sep
          .. "tests"
          .. sep
          .. "?.lua",
        base .. sep .. "plugin" .. sep .. "tests" .. sep .. "?/init.lua",
      }, ";")
    end
  end
  return ""
end

local plugin_paths = findPluginPackagePath("https://github.com/ar-at-localhost/vnix")

package.path = package.path
  .. (plugin_paths ~= "" and (";" .. plugin_paths) or "")
  .. ";/home/ar/.luarocks/share/lua/5.4/?.lua"
  .. ";/home/ar/.luarocks/share/lua/5.4/?/init.lua"

package.cpath = "/home/ar/.luarocks/lib/lua/5.4/?.so;" .. package.cpath

-- Require all the plugin modules
local bootstrap_module = require("vnix.core.bootstrap")
require("vnix.actions.create")
require("vnix.actions.dashboard")
require("vnix.actions.inspect")
require("vnix.actions.kill")
require("vnix.actions.nav")
require("vnix.actions.pane")
require("vnix.actions.rename")
require("vnix.actions.split")
require("vnix.actions.status-bar")
require("vnix.actions.switch")
require("vnix.actions.timesheet")
require("vnix.actions.ui")

wezterm.on("gui-startup", function()
  local startup = require("vnix.core.startup")
  wezterm.log_info("vnix: gui-startup")

  -- start polling for gui_startup
  wezterm.log_info("vnix: gui-startup attempt")
  startup.gui_startup()
  wezterm.log_info("vnix: gui-startup attempt end")
end)

local M = {}

-- This is the main entry point for the user to configure the plugin.
---
---@param config Config
---@param opts VNixConfig
function M.apply_to_config(config, opts)
  -- 1. Process the user's options, merging them with defaults.
  local config_module = require("vnix.core.config")
  local final_opts = config_module.new(opts)

  -- 2. Run the setup process with the final configuration.
  bootstrap_module.setup(final_opts)

  -- 3. Generate the keybindings based on the final configuration.
  local keys_module = require("vnix.core.keys")
  local keybindings = keys_module.get_keybindings(final_opts.keys)
  local key_tables = keys_module.get_key_tables(keybindings)

  -- 4. Inject the generated keybindings into the main WezTerm config.
  if not config.keys then
    config.keys = {}
  end

  for _, key_info in ipairs(keybindings) do
    table.insert(config.keys, key_info)
  end

  -- 5. Inject the key_tables.
  if not config.key_tables then
    config.key_tables = {}
  end

  for k, kt in pairs(key_tables) do
    config.key_tables[k] = kt
  end

  config.status_update_interval = final_opts.status_update_interval
    or config.status_update_interval
    or nil
end

return M
