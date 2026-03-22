local wezterm = require("wezterm")
local rpc = require("vnix.rpc")
local events = require("vnix.events")
local state = require("vnix.state")

---@type VNixGlobal
local vnix = wezterm.GLOBAL.vnix

---@class VnixSwitchActionsMod
local M = {} ---@type VnixSwitchActionsMod

---@param win Window
---@param workspace string
function M.switch_to_workspace_action(win, workspace)
  win:perform_action(
    wezterm.action.SwitchToWorkspace({
      name = workspace,
    }),
    win:active_pane()
  )
end

---@param win Window
---@param workspace string
---@param tab_idx number 0-based
function M.switch_to_tab_action(win, workspace, tab_idx)
  if not workspace or not tab_idx then
    return
  end

  M.switch_to_workspace_action(win, workspace)
  win:perform_action(wezterm.action.ActivateTab(tab_idx), win:active_pane())
end

---@param win Window
---@param pane VnixPaneRuntime?
function M.switch_to_pane_action(win, pane)
  pane = pane or vnix.nvim and vnix.nvim.pane

  if not pane then
    return
  end

  local idx = pane.idx
  M.switch_to_tab_action(win, pane.workspace, pane.tab_idx)
  win:perform_action(wezterm.action.ActivatePaneByIndex(idx), win:active_pane())
  vnix.runtime.active_pane = pane
  M._update_recency()
end

---@param win Window
---@param workspace VnixWorkspaceRuntime
---@param workspace_idx integer
function M.switch_to_workspace(win, workspace, workspace_idx)
  local pane

  if workspace.lazy and not workspace.lazy_loaded then
    ---@diagnostic disable-next-line: cast-type-mismatch
    workspace = state:load_workspace(workspace, workspace_idx)
    pane = workspace.tabs[1].pane
    pane.idx = 0
  else
    pane = vnix.runtime.focus[workspace.name] or workspace.tabs[1].pane
  end

  if pane then
    M.switch_to_pane_action(win, pane)
  end
end

---@param win Window
---@param workspace VnixWorkspaceRuntime
---@param tab VnixTabRuntime
---@param tab_idx integer
function M.switch_to_tab(win, workspace, tab, tab_idx)
  ---@type VnixPaneRuntime
  local pane

  if tab and tab_idx then
    if tab.lazy and not tab.lazy_loaded then
      tab = state:load_tab(workspace.name, tab, tab_idx)
      pane = tab.pane
      pane.idx = 0
    else
      pane = vnix.runtime.focus[workspace.name .. "." .. tab.name] or tab.pane
    end

    if pane then
      M.switch_to_pane_action(win, pane)
    end
  end
end

---@param win Window
function M.sync_pane(win)
  local pane = win:active_pane()
  local pane_state = state:find_pane_by_id(pane and pane:pane_id() or 0)
  vnix.runtime.active_pane = pane_state or vnix.runtime.active_pane
  M._update_recency()
end

function M._update_recency()
  if vnix.runtime.active_pane then
    vnix.runtime.recency_counter = vnix.runtime.recency_counter + 1
    vnix.runtime.recency[tostring(vnix.runtime.active_pane.id)] = vnix.runtime.recency_counter
  end
end

wezterm.on("vnix:switch", function(win, pane)
  -- Validate input parameters
  if not win or not pane or not vnix then
    return
  end

  rpc.dispatch(win, pane, {
    id = 0,
    return_to = 0,
    type = "switch",
    workspace = "",
    data = vnix.runtime.recency or {},
  })
end)

events.make_event(
  "vnix:switch-to-pane",
  ---@param win Window
  ---@param id integer
  ---@param force? boolean
  function(win, id, force)
    local pane = state:find_pane_by_id(id)
    if pane or force then
      M.switch_to_pane_action(win, pane)
    end
  end
)

events.make_event(
  "vnix:switch-to-last-active-pane",
  ---@param win Window
  function(win)
    M.switch_to_pane_action(win, vnix.runtime.active_pane)
  end
)

events.make_event(
  "vnix:switch-by-names",
  ---@param win Window
  ---@param workspace_name string
  ---@param tab_name string
  ---@param pane_name string
  ---@param ctx? 'pane' | 'tab' | 'workspace'
  function(win, workspace_name, tab_name, pane_name, ctx)
    local pane, _, tab, ti, workspace, wi =
      state:find_pane_by_names(workspace_name, tab_name, pane_name)

    if not pane or not tab or not ti or not workspace or not wi then
      error("No such pane.")
    end

    if ctx == "workspace" or (workspace.lazy and not workspace.lazy_loaded) then
      return M.switch_to_workspace(win, workspace, wi)
    elseif ctx == "tab" or (tab.lazy and not tab.lazy_loaded) then
      return M.switch_to_tab(win, workspace, tab, ti)
    end

    M.switch_to_pane_action(win, pane)
  end
)

return M
