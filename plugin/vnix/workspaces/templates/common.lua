local TableUtils = require("vnix.utils.table")

local M = {}

--- @param base PaneRequireds
--- @param a? PaneOptionals
--- @param b? PaneOptionals
function M.merge(base, a, b)
  return TableUtils.merge_all(base, a, b)
end

--- @class VSplitOverries
--- @field left? PaneOptionals
--- @field right? PaneOptionals

--- @param base PaneRequireds
--- @param offset? number The offset to calculate the links
--- @param opts VSplitOverries Overrides
function M.vsplit(base, offset, opts)
  opts = opts or { left = {}, right = {} }
  offset = offset or 0
  assert(offset + 2 >= 1, "Pane index must be >= 1")

  --- @type PaneSpec[]
  local vsplit = {
    -- Left Pane
    M.merge(base, opts.left, {
      first = "right",
      right = offset + 1,
    }),

    -- Right Pane
    M.merge(base, opts.right, {
      left = offset,
    }),
  }

  return vsplit
end

--- @class HSplitOverries
--- @field top? PaneOptionals
--- @field bottom? PaneOptionals

--- @param base PaneRequireds
--- @param offset? number The offset to calculate the links
--- @param opts HSplitOverries Overrides
function M.hsplit(base, offset, opts)
  opts = opts or { top = {}, bottom = {} }
  offset = offset or 0
  assert(offset + 2 >= 1, "Pane index must be >= 1")

  --- @type PaneSpec[]
  local hsplit = {
    -- Left Pane
    M.merge(base, opts.top, {
      first = "bottom",
      bottom = offset + 1,
    }),

    -- Right Pane
    M.merge(base, opts.bottom, {
      top = offset,
    }),
  }

  return hsplit
end

--- @class GridOverries
--- @field top_left? PaneOptionals
--- @field bottom_left? PaneOptionals
--- @field top_right? PaneOptionals
--- @field bottom_right? PaneOptionals

--- @param base PaneRequireds
--- @param offset? number The offset to calculate the links
--- @param opts GridOverries Overrides
function M.grid(base, offset, opts)
  opts = opts or { top = {}, bottom = {} }
  offset = offset or 0
  assert(offset + 2 >= 1, "Pane index must be >= 1")

  --- @type PaneSpec[]
  local grid = {
    -- Top Left Pane
    M.merge(base, opts.top_left, {
      first = "right",
      right = offset + 2,
      bottom = offset + 4,
    }),

    -- Top Right Pane
    M.merge(base, opts.top_right, {
      left = offset,
      first = "bottom",
      bottom = offset + 3,
    }),

    -- Bottom Right Pane
    M.merge(base, opts.bottom_right, {
      top = offset + 1,
    }),

    -- Bottom Left Pane
    M.merge(base, opts.bottom_left, {
      top = offset + 2,
      left = offset + 1,
    }),
  }

  return grid
end

return M
