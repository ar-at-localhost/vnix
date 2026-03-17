---@class StateUtils
local M = {} ---@type StateUtils

---Convert workspace to spec
---@param workspace VnixWorkspaceRuntime
---@return VnixWorkspace
function M.workspace_to_spec(workspace)
  ---@type VnixWorkspace
  local spec = {
    name = workspace.name,
    cwd = workspace.cwd,
    env = workspace.env,
    lazy = workspace.lazy,
    meta = workspace.meta,
    tabs = vim.tbl_map(function(tab)
      return M.tab_to_specs(tab)
    end, workspace.tabs),
  }

  return spec
end

---Convert tab to spec
---@param tab VnixTabRuntime
---@return VnixTab
function M.tab_to_specs(tab)
  ---@type VnixTab
  local spec = {
    name = tab.name,
    cwd = tab.cwd,
    env = tab.env,
    lazy = tab.lazy,
    meta = tab.meta,
    pane = M.pane_to_spec(tab.pane),
  }

  return spec
end

---@param pane VnixPaneRuntime
---@return VnixPane
function M.pane_to_spec(pane)
  ---@type VnixPane
  local spec = {
    name = pane.name,
    cwd = pane.cwd,
    env = pane.env,
    args = pane.args,
    size = pane.size,
    right = pane.right and M.pane_to_spec(pane.right),
    bottom = pane.bottom and M.pane_to_spec(pane.bottom),
    first_split = pane.first_split,
    meta = pane.meta,
  }

  return spec
end

return M
