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
  local specs = fs.read_json(vnix.specs_file_secondary)

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

  if not specs.procs then
    specs.procs = {
      {
        title = "Quit Vnix",
        cmd = string.format("kill -9 %d", wezterm.procinfo.pid() or -1),
        desc = "Force kill vnix",
      },
    }
  end

  for _, w in ipairs(specs.workspaces) do
    if w.layout then
      local template = templates.get_workspace_template(w.layout.name)
      if template then
        specs.workspaces[_] = template.apply(w.layout.opts, w)
      end
    end

    if not w.procs or type(w.procs) ~= "table" or not w.procs[1] then
      w.procs = {}
    end

    for _, p in ipairs(w.procs) do
      ---@cast p VnixProcRuntime
      p.workspace = w.name
      p.status = "ready"
    end
  end

  return specs
end

return M
