local wezterm = require("wezterm")
local fs = require("vnix.utils.fs")
local misc = require("vnix.utils.misc")
local templates = require("vnix.workspaces.templates")
local vnix = wezterm.GLOBAL.vnix
local M = {}

function M.load_from_file(file_name)
  if not file_name then
    file_name = vnix.state_file
  end

  --- @type StateSpecs
  local state = misc.keys_to_num(fs.safe_read_json(file_name, wezterm.json_parse("[]")))
  --- @type State
  local out = {}
  --- @type LayoutSpec[]
  local layout_specs = {}

  for _, v in ipairs(state) do
    if v.spec_type == "layout" then
      table.insert(layout_specs, v)
    else
      table.insert(out, v)
    end
  end

  for _, v in ipairs(layout_specs) do
    local specs = templates.apply_layout(v, #out)
    for _, spec in ipairs(specs) do
      table.insert(out, spec)
    end
  end

  return out
end

return M
