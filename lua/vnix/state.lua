local wezterm = require("wezterm")
local common = require("common")
local vnix_mux = require("vnix.mux")
local t = require("common.time")
local vnix = wezterm.GLOBAL.vnix

---@class VnixStateMod
---@field _write? table<number, 1>
local M = {
  _write = {},
} ---@type VnixStateMod
M.__index = M

function M:new()
  local o = setmetatable({}, self)
  return o
end

---@param action fun()
---@param opts? { reset_workspace?: VnixWorkspaceRuntime | true}
function M:_make_mutation(action, opts)
  table.insert(self._write, 1)
  action()

  if opts then
    if opts.reset_workspace then
      local workspaces = vnix.runtime.workspaces
      if type(opts.reset_workspace) == "table" then
        local w = opts.reset_workspace
        ---@cast w VnixWorkspaceRuntime
        workspaces = { w }
      end

      for _, w in ipairs(workspaces) do
        for _, p in pairs(w.procs or {}) do -- note: `pairs`
          if not p.id then
            p.id = string.format("%s/%s", w.name, p.title)
          end
        end
      end
    end

    self:reset_flat_state()
  end

  table.remove(self._write)
  if #self._write <= 0 then
    self:_save()
  end
end

function M:_save()
  pcall(function()
    local fs = require("common.fs")
    fs.write_json(vnix.vnix_dir .. "/runtime.json", vnix.runtime)
  end)
end

---@param workspace VnixWorkspace
---@param index integer
function M:load_workspace(workspace, index)
  local updated = workspace

  self:_make_mutation(
    function()
      local w = vnix_mux.create_workspace(workspace, true, index)
      w.lazy_loaded = true
      M:save_workspace(w)
      updated = w
    end,
    ---@cast updated VnixWorkspaceRuntime
    { reset_workspace = updated }
  )

  ---@cast updated VnixWorkspaceRuntime
  return updated
end

---@param workspace_name string
---@param tab VnixTab
---@param idx integer
function M:load_tab(workspace_name, tab, idx)
  self:_make_mutation(function()
    local workspace = M:find_workspace_by_name(workspace_name)
    if not workspace then
      error("Failed to acquire workspace!")
    end

    tab = vnix_mux.create_tab(tab, workspace_name, idx)
    tab.lazy_loaded = true
    M:save_tab(tab, workspace, idx)
  end)

  ---@cast tab VnixTabRuntime
  return tab
end

---Set workspace's state
---@param workspaces VnixWorkspaceRuntime[]
function M:set_workspaces(workspaces)
  self:_make_mutation(function()
    vnix.runtime.workspaces = workspaces
  end, { reset_workspace = true })
end

---Save a workspace
---@param workspace VnixWorkspaceRuntime Stateful workspace
---@param at? integer
function M:save_workspace(workspace, at)
  self:_make_mutation(function()
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
  end, {
    reset_workspace = workspace,
  })
end

---Get workspace's state
---@return VnixWorkspaceRuntime[]
function M:get_workspaces()
  return vnix.runtime.workspaces
end

---Remove a workspace (from both state / config)
---@param idx integer index (1-base)
function M:remove_workspace(idx)
  self:_make_mutation(function()
    do
      local workspaces = {}

      for i, v in ipairs(vnix.runtime.workspaces) do
        if i ~= idx then
          table.insert(workspaces, v)
        end
      end

      vnix.runtime.workspaces = workspaces
    end
  end, {
    reset_workspace = true,
  })
end

---@param target string Target workspace name
---@param name string New name
function M:rename_workspace(target, name)
  self:_make_mutation(function()
    local workspace = M:find_workspace_by_name(target)
    if not workspace then
      error(string.format("No such workspace: %s", target))
    end

    workspace.name = name
    M:save_workspace(workspace)
  end)
end

function M:find_workspace_by_name(name)
  local workspaces = M:get_workspaces()

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
function M:save_tab(tab, workspace, at)
  local idx

  self:_make_mutation(function()
    workspace = workspace or M:find_workspace_by_name(tab.pane.workspace)
    if not workspace then
      error("No such workspace:" .. tostring(tab.pane.workspace))
    end

    idx = at or (#workspace.tabs + 1)
    local tabs = {}

    for i, v in ipairs(workspace.tabs) do
      if i ~= at then
        table.insert(tabs, v)
      end
    end

    table.insert(tabs, idx, tab)
    workspace.tabs = tabs
  end)

  ---@cast workspace VnixWorkspaceRuntime
  return workspace, tab, idx
end

---Remove a tab
---@param workspace VnixWorkspaceRuntime target workspace
---@param idx integer index of tab to be remove (1-based)
---@return integer count the new length of tabs in workspace
---@return integer idx removed tab's index
function M:remove_tab(workspace, idx)
  self:_make_mutation(function()
    local tabs = {}

    for i, v in ipairs(workspace.tabs) do
      if i ~= idx then
        table.insert(tabs, v)
      end
    end

    workspace.tabs = tabs
  end)

  return #workspace.tabs, idx
end

---Rename a tab
---@param workspace VnixWorkspaceRuntime target workspace
---@param id integer Wezterm Tab ID
---@param name string new name
---@return integer idx removed tab's wezterm ID
function M:rename_tab(workspace, id, name)
  ---@type VnixTabRuntime
  local tab = nil

  self:_make_mutation(function()
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
  end)

  return id
end

---Rename a pane
---@param id integer Wezterm Pane ID
---@param name string new name
---@return integer id removed pane's Wezterm ID
function M:rename_pane(id, name)
  self:_make_mutation(function()
    local pane = M:find_pane_by_id(id)

    if not pane then
      error(string.format("No such pane: %d", id))
    end

    pane.name = name
  end)

  return id
end

---Update pane
---@param pane Pane
function M:update_pane(pane)
  local id = pane:pane_id()

  self:_make_mutation(function()
    local pane_state, _, _, w, wi = M:find_pane_by_id(id)

    if not pane_state or not w or not wi then
      error(string.format("No such pane: %d", id))
    end

    local d = pane:get_dimensions()
    pane_state.size = {
      width = d.cols,
      height = d.viewport_rows,
    }

    self:save_workspace(w, wi)
  end)

  return id
end

function M:remove_pane(pane)
  self:_make_mutation(function()
    local workspaces = M:get_workspaces()

    for _, w in ipairs(workspaces) do
      if w.name == pane.workspace then
        for i, tab in ipairs(w.tabs) do
          if tab.name == pane.tab then
            local found = M:_find_pane(tab.pane, pane)

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
  end)
end

function M:find_pane(workspace_name, tab_id, pane_id)
  local workspaces = M:get_workspaces()
  for _, w in ipairs(workspaces) do
    if w.name == workspace_name then
      for _, tab in ipairs(w.tabs) do
        if tab.id == tab_id and tab.pane then
          return M:_dfs_find(tab.pane, pane_id)
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
function M:find_pane_by_names(workspace_name, tab_name, pane_name)
  local workspaces = M:get_workspaces()
  for wi, workspace in ipairs(workspaces) do
    if workspace.name == workspace_name then
      for ti, tab in ipairs(workspace.tabs) do
        if tab.name == tab_name and tab.pane then
          local found, parent = M:_dfs_find(tab.pane, pane_name)
          if found then
            return found, parent, tab, ti, workspace, wi
          end
        end
      end

      return
    end
  end
end

function M:_find_pane(source, target)
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
    local found = M:_find_pane(source.right, target)

    if found then
      return found
    end
  end

  if source.bottom then
    local found = M:_find_pane(source.bottom, target)

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
function M:_dfs_find(node, pane_id_or_name, check)
  if node then
    if
      (type(pane_id_or_name) == "string" and node.name == pane_id_or_name)
      or ((type(pane_id_or_name) == "number") and node.id == pane_id_or_name)
      or check and check(node)
    then
      return node, nil
    end

    -- search right
    local found, parent = M:_dfs_find(node.right, pane_id_or_name, check)
    if found then
      return found, parent or node
    end

    -- search bottom
    found, parent = M:_dfs_find(node.bottom, pane_id_or_name, check)
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
function M:traverse_pane(node, cb)
  ---@cast node VnixPane
  if not node then
    return nil
  end

  M:traverse_pane(node.right, cb)
  M:traverse_pane(node.bottom, cb)
  cb(node)
end

---Traverse all panes in state
---@param cb fun(p: VnixPaneRuntime, t: VnixTabRuntime, w: VnixWorkspaceRuntime,  wi: integer, ti: integer)
---@return nil
function M:traverse_all_panes(cb)
  local workspaces = M:get_workspaces()
  for wi, w in ipairs(workspaces) do
    for ti, tab in ipairs(w.tabs) do
      M:traverse_pane(tab.pane, function(p)
        cb(p, tab, w, wi, ti)
      end)
    end
  end
end

---Find a tab by Wezterm ID
---@param workspace VnixWorkspaceRuntime
---@return VnixTabRuntime?
---@return integer?
function M:find_tab_by_id(workspace, id)
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
function M:find_pane_by_id(id, check)
  local workspaces = M:get_workspaces()
  for wi, w in ipairs(workspaces) do
    for ti, tab in ipairs(w.tabs) do
      if not id and tab.pane then
        return tab.pane, tab, ti, w, wi, nil
      end

      local pane, parent_pane = M:_dfs_find(tab.pane, id, check)

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
function M:find_proc(id, workspace)
  local procs = vnix.runtime.procs
  if workspace then
    procs = workspace.procs
  end

  for i, v in pairs(procs) do
    if v.id == id then
      return v, i
    end
  end
end

---Find a proc by tab_id
---@param id integer
---@return VnixProcRuntime? proc
---@return VnixProcRuntime[]? source
---@return VnixWorkspaceRuntime? workspace
function M:find_proc_by_tab_id(id)
  for _, v in pairs(vnix.runtime.procs) do
    if v.tab_id == id then
      return v, vnix.runtime.procs, nil
    end
  end

  for _, w in ipairs(vnix.runtime.workspaces) do
    for _, v in pairs(w.procs or {}) do
      if v.tab_id == id then
        return v, w.procs, w
      end
    end
  end
end

---Update a proc info
---@param proc VnixProcRuntime
---@param tab MuxTab?
---@param workspace VnixWorkspaceRuntime?
---@param skip_save boolean?
function M:update_proc(proc, tab, workspace, skip_save)
  ---@type VnixProcRuntime?
  local proc_found

  ---@type integer?
  local idx

  self:_make_mutation(function()
    if not workspace and proc.workspace ~= common.vnix_token then
      error("Invalid workspace!")
    end

    proc_found, idx = M:find_proc(proc.id, workspace)
    if not proc_found or not idx then
      error(string.format("Proc by id %s not found!", proc.id or ""))
    end

    if tab then
      proc_found.tab_id = tab:tab_id()
      local pane = tab:panes()[1]
      if pane then
        proc_found.scrollback = pane:get_lines_as_escapes(30)
        proc_found.status = "running"
      end
    else
      proc_found.tab_id = nil
      proc_found.status = "stopped"
      proc_found.scrollback = ""
    end

    proc_found.last_updated = t.now_unix()
  end, not skip_save and { reset_workspace = workspace or true } or nil)

  return proc_found, idx
end

function M:reset_flat_state()
  local out = {} ---@type VnixPanesFlat
  local counter = 10000

  M:traverse_all_panes(function(pane, tab, workspace)
    counter = counter + 1
    local id = (
      (workspace.lazy and not workspace.lazy_loaded) or (tab.lazy and not tab.lazy_loaded)
    )
        and counter
      or pane.id

    ---@type VnixPaneFlat
    local entry = {
      pane_id = id,
      recency = vnix.runtime.recency[tostring(id)] or vnix.runtime.recency_counter or 0,
      pane_idx = pane.idx,
      pane_name = pane.name,
      tab_id = tab.id,
      tab_idx = tab.idx,
      tab_name = tab.name,
      workspace = workspace.name,
      cwd = pane.cwd or tab.cwd or workspace.cwd,
      meta = pane.meta,
      lazy_status = ((not workspace.lazy) and not tab.lazy and "")
        or (workspace.lazy and not workspace.lazy_loaded and "workspace")
        or (tab.lazy and not tab.lazy_loaded and "tab")
        or "loaded",
    }

    table.insert(out, entry)
  end)

  vnix.runtime.panes = out
end

M.instance = M.instance or M:new()
return M.instance
