local wezterm = require("wezterm")

local bootstrap_module = require("vnix.bootstrap")
require("vnix.actions.create")
require("vnix.actions.dashboard")
require("vnix.actions.debug")
require("vnix.actions.inspect")
require("vnix.actions.kill")
require("vnix.actions.nav")
require("vnix.actions.org")
require("vnix.actions.pane")
require("vnix.actions.procs")
require("vnix.actions.rename")
require("vnix.actions.state")
require("vnix.actions.status-bar")
require("vnix.actions.switch")
require("vnix.actions.tab")
require("vnix.actions.ui")

wezterm.on("gui-startup", function()
  local startup = require("vnix.startup")
  -- start polling for gui_startup
  startup.gui_startup()
end)

local M = {}

-- This is the main entry point for the user to configure the plugin.
---
---@param config Config
---@param opts VNixConfig
function M.apply_to_config(config, opts)
  local config_module = require("vnix.config")
  local final_opts = config_module.new(opts)

  bootstrap_module.setup(final_opts)
  require("vnix.keys").setup(config, opts.keys)

  config.status_update_interval = final_opts.status_update_interval
    or config.status_update_interval
    or nil

  print("Lost...")
  local debug = require("vnix.debug")
  debug.handle_reload()
end

return M
