local dev = require("vnix.workspaces.templates.dev")

--- @class AvailableLayout
--- @field name string
--- @field desc string
---
--- @alias AvailableLayoutNames 'dev'

local M = {}

--- @function Apply layouts to state
--- @param spec LayoutSpec
--- @param offset? number
--- @return PaneSpec[]
function M.apply_layout(spec, offset)
  assert(
    spec.spec_type == "layout",
    "Layouts can not be applied to type" .. tostring(spec.spec_type)
  )

  --- @type AvailableLayoutNames | nil
  local layout = spec.layout
  offset = offset or 0

  if layout == "dev" then
    spec.opts = spec.opts or {}
    spec.opts.name = spec.opts.name or ("dev-" .. tostring(offset))
    return dev.workspace(spec.opts.name, offset, spec.opts)
  end

  error("Invalid type of layout requested to be applied: " .. layout)
end

--- @return AvailableLayout[]
function M.get_layouts()
  return {
    {
      name = "dev",
      desc = "A layout suitable for development",
    },
  }
end

return M
