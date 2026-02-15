local wezterm = require("wezterm")
local vnix = wezterm.GLOBAL.vnix

---@class VnixStateMod
---@field remove_pane fun(pane: VnixPaneState): nil Remove a pane
---@field find_pane fun(workspace: string, tab: number, pane: number): VnixPaneState? Find a pane by identities
---@field find_workspace_by_name fun(name: string): VnixWorkspaceState?, number? Find a pane by identities
---@field find_tab_by_id fun(workspace: VnixWorkspaceState, id: number): VnixTabState?, number? Find a pane by identities
---@field _find_pane fun(source: VnixPaneState, target: VnixPaneState): VnixPaneState? Remove a panes in the tree & returns it
---@field traverse_pane fun(node: VnixPaneState, cb: fun(i: VnixPaneState): nil): nil Traverse a state node
---@field traverse_all_panes fun(cb: fun(p: VnixPaneState, t: VnixTabState, w: VnixWorkspaceState): nil): nil Traverse all panes in the state
local M = {} ---@type VnixStateMod

---Set workspace's state
---@param workspaces VnixWorkspaceState[]
function M.set_workspaces(workspaces)
  vnix.workspaces = workspaces
end

---Get workspace's state
---@return VnixWorkspaceState[]
function M.get_workspaces()
  return vnix.workspaces
end

---Save a workspace (to both state / config)
---@param spec VnixWorkspace Original specification
---@param workspace VnixWorkspaceState Stateful workspace
function M.save_workspace(spec, workspace)
  do
    local workspaces = {}

    for _, v in ipairs(vnix.workspaces) do
      table.insert(workspaces, v)
    end

    table.insert(workspaces, workspace)
    vnix.workspaces = workspaces
  end

  do
    local config_workspaces = {}

    for _, v in ipairs(vnix.orig_config.workspaces) do
      table.insert(config_workspaces, v)
    end
    table.insert(config_workspaces, spec)
    vnix.orig_config.workspaces = config_workspaces
  end
end

---Remove a workspace (from both state / config)
---@param idx integer index (1-base)
function M.remove_workspace(idx)
  do
    local workspaces = {}

    for i, v in ipairs(vnix.workspaces) do
      if i ~= idx then
        table.insert(workspaces, v)
      end
    end

    vnix.workspaces = workspaces
  end

  do
    local config_workspaces = {}

    for i, v in ipairs(vnix.orig_config.workspaces) do
      if i ~= idx then
        table.insert(config_workspaces, v)
      end
    end

    vnix.orig_config.workspaces = config_workspaces
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

  do
    local orig_workspace = M.find_workspace_by_name_orig(tab.pane.workspace)
    if orig_workspace then
      local orig_tabs = {}

      for _, v in ipairs(orig_workspace.tabs) do
        table.insert(orig_tabs, v)
      end

      table.insert(orig_tabs, idx, tab)
      orig_workspace.tabs = orig_tabs
    end
  end

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

  do
    local orig_workspace = M.find_workspace_by_name_orig(workspace.name)
    if orig_workspace then
      local orig_tabs = {}

      for i, v in ipairs(orig_workspace.tabs) do
        if i ~= idx then
          table.insert(orig_tabs, v)
        end
      end

      orig_workspace.tabs = orig_tabs
    end
  end

  return #workspace.tabs, idx
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

---Get original workspace spec
---@param name string
---@return VnixWorkspace?
---@return integer?
function M.find_workspace_by_name_orig(name)
  local workspaces = vnix.orig_config.workspaces
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
