local workspace_templates = require("common.templates.workspaces")
local tab_templates = require("common.templates.tabs")
local tbl = require("common.tbl")

---@class VnixTemplatesRegistry
---@field _w VnixWorkspaceTemplate[]
---@field _t VnixTabTemplate[]
local templates = {
  _w = {
    blank = workspace_templates.blank,
    dev = workspace_templates.dev,
  },
  _t = {
    vsplit = tab_templates.vsplit,
    hsplit = tab_templates.hsplit,
    grid = tab_templates.grid,
  },
}

---@class VnixTemplatesMode
local M = {} ---@type VnixTemplatesMode

---Get workspace templates
--- @return VnixWorkspaceTemplate[]
function M.get_workspace_templates()
  local clone = tbl.deep_copy(templates._w)
  ---@type VnixWorkspaceTemplate[]
  local temp = {}

  for _, v in pairs(clone) do
    table.insert(temp, v)
  end

  return temp
end

---Get workspace templates
---@param name string
---@return VnixWorkspaceTemplate?
function M.get_workspace_template(name)
  return tbl.deep_copy(templates._w[name])
end

---Get tab templates
---@return VnixTabTemplate[]
function M.get_tab_templates()
  local clone = tbl.deep_copy(templates._t)
  ---@type VnixTabTemplate[]
  local temp = {}

  for _, v in pairs(clone) do
    table.insert(temp, v)
  end

  return temp
end

---Get tab template
---@param name string
---@return VnixTabTemplate
function M.get_tab_template(name)
  return tbl.deep_copy(templates._t[name])
end

---Get templates
---@return { workspace: WorkspaceTempates[], tab: TabTemplates[] }
function M.get_templates()
  return {
    workspace = M.get_workspace_templates(),
    tab = M.get_tab_templates(),
  }
end

return M
