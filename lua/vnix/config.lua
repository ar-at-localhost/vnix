local wezterm = require("wezterm")
local templates = require("common.templates")
local fs = require("common.fs")

---@class VnixSpecsMod
---@field load fun(path): VnixSpecs load from given file path
local M = {} ---@type VnixSpecsMod

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

function M.load()
  local vnix = wezterm.GLOBAL.vnix

  --- @type VnixSpecs?
  local specs, err = fs.read_json(vnix.specs_file_secondary)

  if not specs then
    specs = fs.safe_read_json(
      vnix.specs_file_primary_out,
      ---@type VnixSpecs
      {
        workspaces = {
          {
            name = "Untitled",
            layout = {
              name = "blank",
              opts = {
                name = "Untitled",
              },
            },
          },
        },
      }
    )
  end

  for _, v in ipairs(specs.workspaces) do
    if v.layout then
      local template = templates.get_workspace_template(v.layout.name)
      if template then
        specs.workspaces[_] = template.apply(v.layout.opts, v)
      end
    end
  end

  return specs
end

return M
