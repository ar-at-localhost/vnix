local tbl = require("common.tbl")
local env = require("common.env")
local home = env.get_env("HOME")

--- @class VSplitTemplateOptions workspace Template Overrides
--- @field name string
--- @field cwd? string workspace current working directory
--- @field left? VnixPane
--- @field right? VnixPane
---
---@class VSplitTemplate: VnixTabTemplate
---@field apply fun(opts: VSplitTemplateOptions): VnixTab
---@field form VnixNvimForm?

--- @class HSplitTemplateOptions workspace Template Overrides
--- @field name string
--- @field cwd? string workspace current working directory
--- @field top? VnixPane
--- @field bottom? VnixPane
---
---@class HSplitTemplate: VnixTabTemplate
---@field apply fun(opts: HSplitTemplateOptions): VnixTab
---@field form VnixNvimForm?

--- @class GridTemplateOptions workspace Template Overrides
--- @field name string
--- @field cwd? string workspace current working directory
--- @field top? VnixPane
--- @field top_right? VnixPane
--- @field bottom? VnixPane
--- @field bottom_right? VnixPane
---
---@class GridTemplate: VnixTabTemplate
---@field apply fun(opts: GridTemplateOptions): VnixTab
---@field form VnixNvimForm?

---@class TabTemplates
---@field vsplit VSplitTemplate
---@field hsplit HSplitTemplate
---@field grid GridTemplate
---@field merge fun(base: VnixPane, overrides?: VnixPane): VnixPane
local M = {} ---@type TabTemplates

function M.merge(base, overrides)
  return tbl.merge_all(base, overrides)
end

M.vsplit = {
  type = "tab",
  name = "Vertical Split",
  desc = "Vertical Split (|)",
  id = "vsplit",

  apply = function(opts)
    if not opts or not opts.name or opts.name == "" then
      error("Name is required!")
    end

    opts.left = opts.left or {}
    opts.right = opts.right or {}

    --- @type VnixTab
    local vsplit = {
      name = opts.name,
      cwd = opts.cwd or home,
      pane = M.merge({
        name = opts.left.name or "Left",

        right = M.merge({
          name = opts.right.name or "Right",
        }, opts.right),
      }, opts.left),
    }

    return vsplit
  end,

  form = {
    title = "New Tab",
    description = "Please provide following details to create Tab.",
    fields = {
      {
        key = "name",
        title = "Name",
        required = true,
        default = "Untitled",
      },
      {
        key = "cwd",
        title = "Current Working directory",
        required = false,
        default = home or "",
      },
    },
  },
}

M.hsplit = {
  type = "tab",
  name = "Horizontal Split",
  desc = "Horizontal Split (-)",
  id = "hsplit",

  apply = function(opts)
    if not opts or not opts.name or opts.name == "" then
      error("Name is required!")
    end

    opts.top = opts.top or {}
    opts.bottom = opts.bottom or {}

    --- @type VnixTab
    local hsplit = {
      name = opts.name,
      cwd = opts.cwd or home,
      pane = M.merge({
        name = opts.top.name or "Top",

        bottom = M.merge({
          name = opts.bottom.name or "Bottom",
        }, opts.bottom),
      }, opts.top),
    }

    return hsplit
  end,

  form = {
    title = "New Tab",
    description = "Please provide following details to create Tab.",
    fields = {
      {
        key = "name",
        title = "Name",
        required = true,
        default = "Untitled",
      },
      {
        key = "cwd",
        title = "Current Working directory",
        required = false,
        default = home or "",
      },
    },
  },
}

M.grid = {
  type = "tab",
  name = "Grid",
  desc = "Grid (-|-)",
  id = "grid",

  apply = function(opts)
    if not opts or not opts.name or opts.name == "" then
      error("Name is required!")
    end

    opts.top = opts.top or {}
    opts.bottom = opts.bottom or {}
    opts.top_right = opts.top_right or {}
    opts.bottom_right = opts.bottom_right or {}

    --- @type VnixTab
    local grid = {
      name = opts.name,
      cwd = opts.cwd or home,

      pane = M.merge({
        name = opts.top.name or "Top Left",

        right = M.merge({
          name = opts.top_right.name or "Top Right",

          bottom = M.merge({
            name = opts.bottom_right.name or "Bottom Right",
          }, opts.bottom_right),
        }, opts.top_right),

        bottom = M.merge({
          name = opts.bottom.name or "Bottom Left",
        }, opts.bottom),
      }, opts.top),
    }

    return grid
  end,

  form = {
    title = "New Tab",
    description = "Please provide following details to create Tab.",
    fields = {
      {
        key = "name",
        title = "Name",
        required = true,
        default = "Untitled",
      },
      {
        key = "cwd",
        title = "Current Working directory",
        required = false,
        default = home or "",
      },
    },
  },
}

return M
