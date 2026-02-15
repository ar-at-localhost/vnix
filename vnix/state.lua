local wezterm = require("wezterm")
local vnix = wezterm.GLOBAL.vnix

---@class VnixStateMod
---@field set_workspaces fun(workspace: VnixWorkspaceState[]) Set workspaces
---@field get_workspaces fun(): VnixWorkspaceState[] Get workspaces
---@field remove_pane fun(pane: VnixPaneState): nil Remove a pane
---@field find_pane fun(workspace: string, tab: number, pane: number): VnixPaneState? Find a pane by identities
---@field find_pane_by_id fun(id?: number): VnixPaneState?, VnixTabState?, number?, VnixWorkspaceState? Find a pane by id, returns first encountered, if no id provided
---@field find_workspace_by_name fun(name: string): VnixWorkspaceState?, number? Find a pane by identities
---@field find_tab_by_id fun(workspace: VnixWorkspaceState, id: number): VnixTabState?, number? Find a pane by identities
---@field _find_pane fun(source: VnixPaneState, target: VnixPaneState): VnixPaneState? Remove a panes in the tree & returns it
---@field _dfs_find fun(node: VnixPaneState, id: number): VnixPaneState? Remove a panes in the tree & returns it
---@field traverse_pane fun(node: VnixPaneState, cb: fun(i: VnixPaneState): nil): nil Traverse a state node
---@field traverse_all_panes fun(cb: fun(p: VnixPaneState, t: VnixTabState, w: VnixWorkspaceState): nil): nil Traverse all panes in the state
---@field save_workspace fun(spec: VnixWorkspace, workspace: VnixWorkspaceState) Save a workspace to the state
local M = {} ---@type VnixStateMod

function M.set_workspaces(workspaces)
  vnix.workspaces = workspaces
end

function M.get_workspaces()
  return vnix.workspaces
end

function M.save_worksapce(spec, workspace)
  table.insert(vnix.workspaces, workspace)
  table.insert(vnix.orig_config.workspaces, spec)
end

function M.find_pane(workspace_name, tab_id, pane_id)
  local workspaces = M.get_workspaces()
  for _, w in ipairs(workspaces) do
    if w.name == workspace_name then
      for _, t in ipairs(w.tabs) do
        if t.id == tab_id and t.pane then
          return M._dfs_find(t.pane, pane_id)
        end
      end
      return nil
    end
  end

  return nil
end

function M.remove_pane(pane)
  local workspaces = M.get_workspaces()

  for _, w in ipairs(workspaces) do
    if w.name == pane.workspace then
      for i, t in ipairs(w.tabs) do
        if t.name == pane.tab then
          local found = M._find_pane(t.pane, pane)

          if found and found.right and found.right.id == pane.id then
            found.right = pane.right or pane.bottom
          elseif found and found.bottom and found.bottom.id == pane.id then
            found.bottom = pane.right or pane.bottom
          elseif t.pane.id == pane.id then
            table.remove(w.tabs, i)
          end

          return
        end
      end
    end
  end
end

function M._find_pane(source, target)
  if (not source or not target) or (source and target and source.id == target.id) then
    return nil
  end

  if
    (source.right and source.right.id == target.id)
    or (source.bottom and source.bottom.id == target.id)
  then
    return source
  end

  if source.right then
    local found = M._find_pane(source.right, target)

    if found then
      return found
    end
  end

  if source.bottom then
    local found = M._find_pane(source.bottom, target)

    if found then
      return found
    end
  end

  return nil
end

function M._dfs_find(node, pane_id)
  if not node then
    return nil
  end

  if node.id == pane_id then
    return node
  end

  return M._dfs_find(node.right, pane_id) or M._dfs_find(node.bottom, pane_id)
end

function M.traverse_pane(node, cb)
  if not node then
    return nil
  end

  M.traverse_pane(node.right, cb)
  M.traverse_pane(node.bottom, cb)
  cb(node)
end

function M.traverse_all_panes(cb)
  local workspaces = M.get_workspaces()
  for _, w in ipairs(workspaces) do
    for _, t in ipairs(w.tabs) do
      M.traverse_pane(t.pane, function(p)
        cb(p, t, w)
      end)
    end
  end
end

function M.find_workspace_by_name(name)
  local workspaces = M.get_workspaces()
  local idx = nil
  local workspace = nil

  for i, w in ipairs(workspaces) do
    if w.name == name then
      workspace = w
      idx = i
      break
    end
  end

  return workspace, idx
end

function M.find_tab_by_id(workspace, id)
  local idx = nil
  local tab = nil

  for i, t in ipairs(workspace.tabs) do
    if t.id == id then
      idx = i
      tab = t
      break
    end
  end

  return tab, idx
end

function M.find_pane_by_id(id)
  local workspaces = M.get_workspaces()
  for _, w in ipairs(workspaces) do
    for i, t in ipairs(w.tabs) do
      if not id and t.pane then
        return t.pane, t, i and (i - 1) or 0, w
      end

      local p = M._dfs_find(t.pane, id)
      if p then
        return p, t, i and (i - 1) or 0, w
      end
    end
  end
end

return M
