local wezterm = require("wezterm")
local vnix = wezterm.GLOBAL.vnix

---@class VnixStateMod
---@field remove_pane fun(pane: VnixPaneState): nil Remove a pane
---@field find_pane fun(workspace: string, tab: number, pane: number): VnixPaneState? Find a pane by identities
---@field find_workspace_by_name fun(name: string): VnixWorkspaceState?, number? Find a pane by identities
---@field find_tab_by_id fun(workspace: VnixWorkspaceState, id: number): VnixTabState?, number? Find a pane by identities
---@field _find_pane fun(source: VnixPaneState, target: VnixPaneState): VnixPaneState? Remove a panes in the tree & returns it
local M = {} ---@type VnixStateMod

---Set workspace's state
---@param workspaces VnixWorkspaceState[]
function M.set_workspaces(workspaces)
  vnix.runtime.workspaces = workspaces
end

---Get workspace's state
---@return VnixWorkspaceState[]
function M.get_workspaces()
  return vnix.runtime.workspaces
end

---Save a workspace (to both state / config)
---@param workspace VnixWorkspaceState Stateful workspace
function M.save_workspace(workspace)
  local found = false
  do
    local workspaces = {}

    for _, v in ipairs(vnix.runtime.workspaces) do
      table.insert(workspaces, v)
      if v.name == workspace.name then
        found = true
      end
    end

    if not found then
      table.insert(workspaces, workspace)
    end

    vnix.runtime.workspaces = workspaces
  end
end

---Remove a workspace (from both state / config)
---@param idx integer index (1-base)
function M.remove_workspace(idx)
  do
    local workspaces = {}

    for i, v in ipairs(vnix.runtime.workspaces) do
      if i ~= idx then
        table.insert(workspaces, v)
      end
    end

    vnix.runtime.workspaces = workspaces
  end
end

---@param target string Target workspace name
---@param name string New name
function M.rename_workspace(target, name)
  local workspace = M.find_workspace_by_name(target)
  if not workspace then
    error(string.format("No such workspace: %s", target))
  end

  workspace.name = name
  M.save_workspace(workspace)
end

function M.find_workspace_by_name(name)
  local workspaces = M.get_workspaces()

  for idx, workspace in ipairs(workspaces) do
    if workspace.name == name then
      return workspace, idx
    end
  end
end

---Save a new tab to the state
---@param tab VnixTabState Target tab
---@param workspace VnixWorkspaceState? Target workspace
---@param at? integer position of insertion
---@return VnixWorkspaceState workspace workspace of insertion
---@return VnixTabState tab inserted tab
---@return number idx index of inserted tab
function M.save_tab(tab, workspace, at)
  workspace = workspace or M.find_workspace_by_name(tab.pane.workspace)
  if not workspace then
    error("No such workspace:" .. tostring(tab.pane.workspace))
  end

  local idx = at or (#workspace.tabs + 1)
  local tabs = {}

  for _, v in ipairs(workspace.tabs) do
    table.insert(tabs, v)
  end

  table.insert(tabs, idx, tab)
  workspace.tabs = tabs

  return workspace, tab, idx
end

---Remove a tab
---@param workspace VnixWorkspaceState target workspace
---@param idx integer index of tab to be remove (1-based)
---@return integer count the new length of tabs in workspace
---@return integer idx removed tab's index
function M.remove_tab(workspace, idx)
  local tabs = {}

  for i, v in ipairs(workspace.tabs) do
    if i ~= idx then
      table.insert(tabs, v)
    end
  end

  workspace.tabs = tabs
  return #workspace.tabs, idx
end

---Rename a tab
---@param workspace VnixWorkspaceState target workspace
---@param id integer Wezterm Tab ID
---@param name string new name
---@return integer idx removed tab's wezterm ID
function M.rename_tab(workspace, id, name)
  ---@type VnixTabState
  local tab = nil

  for _, v in ipairs(workspace.tabs) do
    if v.id == id then
      tab = v
      break
    end
  end

  if not tab then
    error(string.format("No such tab: %d", id))
  end

  tab.name = name
  return id
end

---Rename a pane
---@param id integer Wezterm Pane ID
---@param name string new name
---@return integer id removed pane's Wezterm ID
function M.rename_pane(id, name)
  local pane = M.find_pane_by_id(id)

  if not pane then
    error(string.format("No such pane: %d", id))
  end

  pane.name = name
  return id
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

function M.find_pane_by_names(workspace_name, tab_name, pane_name)
  local workspaces = M.get_workspaces()
  for _, w in ipairs(workspaces) do
    if w.name == workspace_name then
      for _, t in ipairs(w.tabs) do
        if t.name == tab_name and t.pane then
          return M._dfs_find(t.pane, pane_name)
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

---Depth first search for pane by id, name or check
---@param node VnixPaneState
---@param pane_id_or_name? string|number name or id of the pane
---@param check? fun(node: VnixPaneState): boolean
---@return VnixPaneState? found  The found pane
---@return VnixPaneState? parent The parent pane
function M._dfs_find(node, pane_id_or_name, check)
  if node then
    if
      (type(pane_id_or_name) == "string" and node.name == pane_id_or_name)
      or (type(pane_id_or_name) == "number" and node.id == pane_id_or_name)
      or check and check(node)
    then
      return node, nil
    end

    -- search right
    local found, parent = M._dfs_find(node.right, pane_id_or_name, check)
    if found then
      return found, parent or node
    end

    -- search bottom
    found, parent = M._dfs_find(node.bottom, pane_id_or_name, check)
    if found then
      return found, parent or node
    end
  end

  return nil, nil
end

---Traverse a pane node
---@generic T
---@param node T
---@param cb fun(node: T)
---@return nil
function M.traverse_pane(node, cb)
  ---@cast node VnixPane
  if not node then
    return nil
  end

  M.traverse_pane(node.right, cb)
  M.traverse_pane(node.bottom, cb)
  cb(node)
end

---Traverse all panes in state
---@param cb any
---@return nil
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

---Find a tab by Wezterm ID
---@return MuxTab
---@return integer
function M.find_tab_by_id(workspace, id)
  for i, t in ipairs(workspace.tabs) do
    if t.id == id then
      return t, i
    end
  end
end

---Find pane by id or return first maching the check
---@param id? integer
---@param check? fun(p:VnixPaneState, v: VnixPaneState, w: VnixWorkspaceState): boolean
---@return VnixPaneState? pane Pane
---@return VnixTabState? tab Tab
---@return integer? tab_index Tab index (1-based)
---@return VnixWorkspaceState? workspace workspace
---@return integer? workspace_index Index of the workspace (1-based)
---@return VnixPaneState? parent_node Parent of the pane
function M.find_pane_by_id(id, check)
  local workspaces = M.get_workspaces()
  for wi, w in ipairs(workspaces) do
    for ti, t in ipairs(w.tabs) do
      if not id and t.pane then
        return t.pane, t, ti, w, wi, nil
      end

      local pane, parent_pane = M._dfs_find(t.pane, id, check)

      if pane then
        return pane, t, ti, w, wi, parent_pane
      end
    end
  end
end

return M
