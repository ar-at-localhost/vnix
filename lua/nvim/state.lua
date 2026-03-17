local tbl = require("common.tbl")
local config = require("nvim.config")
local state = require("common.state")

---@class StateModule
local M = {} ---@type StateModule

---Process the state file
---@param data VnixPaneFlat[]
function M.process(data)
  config.flat_panes = data
end

---@param workspaces? VnixWorkspaceRuntime[]
function M.workspaces_to_specs(workspaces)
  if not workspaces then
    workspaces = config.workspaces
  end

  return vim.tbl_map(
    ---@param workspace VnixWorkspaceRuntime
    function(workspace)
      return state.workspace_to_spec(workspace)
    end,
    workspaces
  )
end

---@param path string
function M.get_orgfiles_root(path) end

return M
