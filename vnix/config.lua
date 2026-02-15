local wezterm = require("wezterm")
local tbl = require("common.tbl")
local templates = require("common.templates")
local fs = require("vnix.fs")

---@class VnixConfigMod
---@field load_from_file fun(path): VnixConfig load from given file path
local M = {} ---@type VnixConfigMod

-- Default configuration values for the plugin
M.defaults = {
  keys = {}, -- User-defined keybinding overrides
  status_update_interval = 10000,
}

-- This will hold the final, merged configuration
M.options = {}

-- Deep-merges the user's options over the defaults.
-- This ensures that all keys are present.
function M.new(opts)
  opts = opts or {}
  local final_opts = {}

  -- Create a deep copy of defaults to avoid modifying the original table
  for k, v in pairs(M.defaults) do
    -- A simple value copy is sufficient here since defaults are not tables
    final_opts[k] = v
  end

  -- Merge user options
  for k, v in pairs(opts) do
    if v ~= nil then
      final_opts[k] = v
    end
  end

  M.options = final_opts
  return M.options
end

function M.load_from_file(path)
  local vnix = wezterm.GLOBAL.vnix
  if not path then
    path = vnix.config_file
  end

  --- @type VnixConfig
  local cfg = tbl.keys_to_num(fs.safe_read_json(path, wezterm.json_parse("[]")))

  for _, v in ipairs(cfg.workspaces) do
    if v.layout then
      local name = v.layout.name
      v.tabs = templates.resolve_workspace(
        ---@cast name VnixWorkspaceLayoutName
        name,
        v.layout.opts
      )
    end
  end

  return cfg
end

return M
