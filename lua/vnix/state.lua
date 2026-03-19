local wezterm = require("wezterm")
local common = require("common")
local vnix_mux = require("vnix.mux")
local t = require("common.time")
local vnix = wezterm.GLOBAL.vnix

---@class VnixStateMod
---@field remove_pane fun(pane: VnixPaneRuntime): nil Remove a pane
---@field find_pane fun(workspace: string, tab: number, pane: number): VnixPaneRuntime? Find a pane by identities
---@field find_workspace_by_name fun(name: string): VnixWorkspaceRuntime?, integer? Find a pane by identities
---@field find_tab_by_id fun(workspace: VnixWorkspaceRuntime, id: number): VnixTabRuntime?, number? Find a pane by identities
---@field _find_pane fun(source: VnixPaneRuntime, target: VnixPaneRuntime): VnixPaneRuntime? Remove a panes in the tree & returns it
local M = {} ---@type VnixStateMod

---@param win Window
---@param workspace VnixWorkspace
---@param index integer
function M.load_workspace(win, workspace, index)
  local w = vnix_mux.create_workspace(workspace, true, index)
  w.lazy_loaded = true
  M.save_workspace(w)
  -- FIXME: It should've been operation limited to new workspace (`init` would do everything)
  wezterm.emit("vnix:state-update", win, "init")
  return w
end

---@param win Window
---@param workspace_name string
---@param tab VnixTab
---@param idx integer
function M.load_tab(win, workspace_name, tab, idx)
  local workspace = M.find_workspace_by_name(workspace_name)
  if not workspace then
    error("Failed to acquire workspace!")
  end

  tab = vnix_mux.create_tab(tab, workspace_name, idx)
  tab.lazy_loaded = true
  M.save_tab(tab, workspace, idx)
  -- FIXME: It should've been operation limited to new workspace (`init` would do everything)
  wezterm.emit("vnix:state-update", win, "init")
  return tab
end

---Set workspace's state
---@param workspaces VnixWorkspaceRuntime[]
function M.set_workspaces(workspaces)
  vnix.runtime.workspaces = workspaces
end

---Get workspace's state
---@return VnixWorkspaceRuntime[]
function M.get_workspaces()
  return vnix.runtime.workspaces
end

---Save a workspace
---@param workspace VnixWorkspaceRuntime Stateful workspace
---@param at? integer
function M.save_workspace(workspace, at)
  if not at then
    at = #vnix.runtime.workspaces
  end

  do
    local workspaces = {}

    for _, v in ipairs(vnix.runtime.workspaces) do
      if v.name ~= workspace.name then
        table.insert(workspaces, v)
      end
    end

    table.insert(workspaces, at, workspace)
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
---@param tab VnixTabRuntime Target tab
---@param workspace VnixWorkspaceRuntime? Target workspace
---@param at? integer position of insertion
---@return VnixWorkspaceRuntime workspace workspace of insertion
---@return VnixTabRuntime tab inserted tab
---@return number idx index of inserted tab
function M.save_tab(tab, workspace, at)
  workspace = workspace or M.find_workspace_by_name(tab.pane.workspace)
  if not workspace then
    error("No such workspace:" .. tostring(tab.pane.workspace))
  end

  local idx = at or (#workspace.tabs + 1)
  local tabs = {}

  for i, v in ipairs(workspace.tabs) do
    if i ~= at then
      table.insert(tabs, v)
    end
  end

  table.insert(tabs, idx, tab)
  workspace.tabs = tabs
  return workspace, tab, idx
end

---Remove a tab
---@param workspace VnixWorkspaceRuntime target workspace
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
---@param workspace VnixWorkspaceRuntime target workspace
---@param id integer Wezterm Tab ID
---@param name string new name
---@return integer idx removed tab's wezterm ID
function M.rename_tab(workspace, id, name)
  ---@type VnixTabRuntime
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
      for _, tab in ipairs(w.tabs) do
        if tab.id == tab_id and tab.pane then
          return M._dfs_find(tab.pane, pane_id)
        end
      end
      return nil
    end
  end

  return nil
end

---@param workspace_name string
---@param tab_name string
---@param pane_name string
---@return VnixPaneRuntime? pane
---@return VnixPaneRuntime? parent_pane
---@return VnixTabRuntime? tab
---@return integer? tab_index
---@return VnixWorkspaceRuntime? workspace
---@return integer? workspace_index
function M.find_pane_by_names(workspace_name, tab_name, pane_name)
  local workspaces = M.get_workspaces()
  for wi, workspace in ipairs(workspaces) do
    if workspace.name == workspace_name then
      for ti, tab in ipairs(workspace.tabs) do
        if tab.name == tab_name and tab.pane then
          local found, parent = M._dfs_find(tab.pane, pane_name)
          if found then
            return found, parent, tab, ti, workspace, wi
          end
        end
      end

      return
    end
  end
end

function M.remove_pane(pane)
  local workspaces = M.get_workspaces()

  for _, w in ipairs(workspaces) do
    if w.name == pane.workspace then
      for i, tab in ipairs(w.tabs) do
        if tab.name == pane.tab then
          local found = M._find_pane(tab.pane, pane)

          if found and found.right and found.right.id == pane.id then
            found.right = pane.right or pane.bottom
          elseif found and found.bottom and found.bottom.id == pane.id then
            found.bottom = pane.right or pane.bottom
          elseif tab.pane.id == pane.id then
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
---@param node VnixPaneRuntime
---@param pane_id_or_name? string|number name or id of the pane
---@param check? fun(node: VnixPaneRuntime): boolean
---@return VnixPaneRuntime? found  The found pane
---@return VnixPaneRuntime? parent The parent pane
function M._dfs_find(node, pane_id_or_name, check)
  if node then
    if
      (type(pane_id_or_name) == "string" and node.name == pane_id_or_name)
      or ((type(pane_id_or_name) == "number") and node.id == pane_id_or_name)
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
---@param cb fun(p: VnixPaneRuntime, t: VnixTabRuntime, w: VnixWorkspaceRuntime,  wi: integer, ti: integer)
---@return nil
function M.traverse_all_panes(cb)
  local workspaces = M.get_workspaces()
  for wi, w in ipairs(workspaces) do
    for ti, tab in ipairs(w.tabs) do
      M.traverse_pane(tab.pane, function(p)
        cb(p, tab, w, wi, ti)
      end)
    end
  end
end

---Find a tab by Wezterm ID
---@param workspace VnixWorkspaceRuntime
---@return MuxTab
---@return integer
function M.find_tab_by_id(workspace, id)
  for i, tab in ipairs(workspace.tabs) do
    if tab.id == id then
      return tab, i
    end
  end
end

---Find pane by id or return first maching the check
---@param id? integer
---@param check? fun(p:VnixPaneRuntime, t: VnixTabRuntime, w: VnixWorkspaceRuntime): boolean
---@return VnixPaneRuntime? pane Pane
---@return VnixTabRuntime? tab Tab
---@return integer? tab_index Tab index (1-based)
---@return VnixWorkspaceRuntime? workspace workspace
---@return integer? workspace_index Index of the workspace (1-based)
---@return VnixPaneRuntime? parent_node Parent of the pane
function M.find_pane_by_id(id, check)
  local workspaces = M.get_workspaces()
  for wi, w in ipairs(workspaces) do
    for ti, tab in ipairs(w.tabs) do
      if not id and tab.pane then
        return tab.pane, tab, ti, w, wi, nil
      end

      local pane, parent_pane = M._dfs_find(tab.pane, id, check)

      if pane then
        return pane, tab, ti, w, wi, parent_pane
      end
    end
  end
end

---Find a proc
---@param id string
---@param workspace VnixWorkspaceRuntime?
---@return VnixProcRuntime? proc
---@return integer? idx
function M.find_proc(id, workspace)
  local procs = vnix.runtime.procs
  if workspace then
    procs = workspace.procs
  end

  for i, v in ipairs(procs) do
    if v.id == id then
      return v, i
    end
  end
end

---Find a proc by tab_id
---@param id integer
---@return VnixProcRuntime? proc
---@return integer? idx
---@return VnixProcRuntime[]? source
---@return VnixWorkspaceRuntime? workspace
function M.find_proc_by_tab_id(id)
  for i, v in ipairs(vnix.runtime.procs) do
    if v.tab_id == id then
      return v, i, vnix.runtime.procs, nil
    end
  end

  for _, w in ipairs(vnix.runtime.workspaces) do
    if w.procs then
      for i, v in ipairs(w.procs) do
        if v.tab_id == id then
          return v, i, w.procs, w
        end
      end
    end
  end
end

---Update a proc info
---@param proc VnixProcRuntime
---@param tab MuxTab?
---@param workspace VnixWorkspaceRuntime?
function M.update_proc(proc, tab, workspace)
  if not workspace and proc.workspace ~= common.vnix_token then
    error("Invalid workspace!")
  end

  local proc_found, idx = M.find_proc(proc.id, workspace)
  if not proc_found or not idx then
    error(string.format("Proc by id %s not found!", proc.id or ""))
  end

  if tab then
    local pane = tab:panes()[1]
    if pane then
      proc_found.scrollback = pane:get_lines_as_escapes(30)
      proc_found.status = "running"
    end
  else
    proc_found.status = "stopped"
  end

  proc.last_updated = t.now_unix()
end

function M.save()
  pcall(function()
    local fs = require("common.fs")
    fs.write_json(vnix.vnix_dir .. "/runtime.json", vnix.runtime)
  end)
end

return M
