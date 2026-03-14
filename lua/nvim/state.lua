local tbl = require("common.tbl")
local config = require("nvim.config")
local state = require("common.state")

---@class StateModule
local M = {} ---@type StateModule

---Process the state file
---@param data VnixPaneFlat[]
function M.process(data)
  config.flat_panes = data

  do
    local dev_workspaces = {}

    for i, v in ipairs(config.flat_panes) do
      if v.meta and v.meta["layout"] and v.meta["layout"] == "dev" then
        dev_workspaces[v.workspace] = {
          idx = i,
          cwd = v.cwd,
        }
      end
    end

    if not tbl.deep_equal(dev_workspaces, config.dev_workspaces) then
      config.dev_workspaces = dev_workspaces
    end
  end
end

---@param workspaces? VnixWorkspaceState[]
function M.workspaces_to_specs(workspaces)
  if not workspaces then
    workspaces = config.workspaces
  end

  return vim.tbl_map(
    ---@param workspace VnixWorkspaceState
    function(workspace)
      return state.workspace_to_spec(workspace)
    end,
    workspaces
  )
end

return M
