--TODO: Activate
local wezterm = require("wezterm")
local rpc = require("vnix.rpc")
local mux = require("vnix.mux")
local state = require("vnix.state")
local templates = require("common.templates")
local vnix = wezterm.GLOBAL.vnix
local events = require("vnix.events")

---@class VnixCreateActions
local M = {}

---Create new workspace
---@param win Window
---@param pane Pane
---@param data VnixWorkspace
---@param callback fun()
function M.create_workspace(win, pane, data, callback)
  local flat = data

  if data.layout then
    local template = templates.get_workspace_template(flat.layout.name)
    if template then
      flat = template.apply(data.layout.opts, flat)
    end
  end

  local workspace, _ = mux.create_workspace(flat)
  state.save_workspace(data, workspace)

  win:perform_action(
    wezterm.action.SwitchToWorkspace({
      name = workspace.name,
    }),
    pane
  )

  win:perform_action(wezterm.action.ActivateTab(0), pane)
  win:perform_action(wezterm.action.ActivatePaneByIndex(0), pane)

  if callback then
    callback()
  else
    -- FIXME: It should've been operation limited to new workspace (`init` would do everything)
    wezterm.emit("vnix:state-update", win, "init")
  end
end

---Create a new tab
---@param win Window
---@param pane Pane
---@param data VnixTab
---@param callback fun()
function M.create_tab(win, pane, data, callback)
  local pane_info = vnix.activity.active_pane
  if not pane_info then
    error("Failed to acquire active pane!")
  end

  local mux_win = mux.find_mux_win(pane_info.workspace)
  if not mux_win then
    error("Unable to acquire active mux window!")
  end

  local workspace = state.find_workspace_by_name(pane_info.workspace)
  if not workspace then
    error("Unable to acquire active workspace!")
  end

  data.cwd = data.cwd or workspace.cwd
  local tab = mux.create_tab(data, mux_win, workspace.name, #workspace.tabs)
  local _, _, count = state.save_tab(tab)

  win:perform_action(
    wezterm.action.SwitchToWorkspace({
      name = workspace.name,
    }),
    pane
  )

  win:perform_action(wezterm.action.ActivateTab(count - 1), pane)

  if callback then
    callback()
  else
    -- FIXME: It should've been operation limited to new workspace (`init` would do everything)
    wezterm.emit("vnix:state-update", win, "init")
  end
end

events.make_event("vnix:create-workspace", M.create_workspace)
events.make_event("vnix:create-tab", M.create_tab)
events.make_event(
  "vnix:create",
  ---Callback
  ---@param win Window
  ---@param pane Pane
  ---@param t 'workspace' | 'tab'
  function(win, pane, t)
    rpc.dispatch(
      win,
      pane,
      {
        id = 0,
        return_to = 0,
        type = "create",
        data = t,
      } ---@type UIMessageCreateReq
    )
  end
)

return M
