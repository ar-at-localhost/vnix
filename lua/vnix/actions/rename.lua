local wezterm = require("wezterm")
local events = require("vnix.events")
local state = require("vnix.state")
local mux = require("vnix.mux")
local vnix = wezterm.GLOBAL.vnix

---@class VnixRenameEvents
local M = {} ---@type VnixRenameEvents

---Rename workspace
---@param win Window
---@param pane Pane
---@param target string Target workspace name
---@param name string New name
---@param skip_update boolean?
---@diagnostic disable-next-line: unused-local
function M.rename_workspace(win, pane, target, name, skip_update)
  local mux_workspace = mux.find_win(target)

  if not mux_workspace then
    error(string.format("No such workspace: %s", target))
  end

  mux_workspace:set_workspace(name)
  state.rename_workspace(target, name)

  if not skip_update then
    -- FIXME: It should've been operation limited to new workspace (`init` would do everything)
    wezterm.emit("vnix:state-update", win, "init")
  end
end

---Raname tab
---@param win Window
---@param pane Pane
---@param tid integer Target Tab's Wezterm ID
---@param name string New name
---@param skip_update boolean?
---@diagnostic disable-next-line: unused-local
function M.rename_tab(win, pane, tid, name, skip_update)
  local tab, mux_win = mux.find_tab(tid)
  if not tab or not mux_win then
    error(string.format("No such tab: %d", tid))
  end

  local workspace_name = mux_win:get_workspace() or ""
  local workspace = state.find_workspace_by_name(workspace_name)
  if not workspace then
    error(string.format("No such workspace: %s", workspace_name))
  end

  tab:set_title(name)
  state.rename_tab(workspace, tid, name)

  if not skip_update then
    -- FIXME: It should've been operation limited to new workspace (`init` would do everything)
    wezterm.emit("vnix:state-update", win, "init")
  end
end

---Raname pane
---@param win Window
---@param pane Pane
---@param pid integer Target Pane's Wezterm ID
---@param name string New name
---@param skip_update? boolean
---@diagnostic disable-next-line: unused-local
function M.rename_pane(win, pane, pid, name, skip_update)
  local p, t, w = mux.find_pane(pid)
  if not p or not t or not w then
    error(string.format("No such pane: %d", pid))
  end

  state.rename_pane(pid, name)

  if not skip_update then
    -- FIXME: It should've been operation limited to new workspace (`init` would do everything)
    wezterm.emit("vnix:state-update", win, "init")
  end
end

events.make_event("vnix:rename-workspace", M.rename_workspace)
events.make_event("vnix:rename-tab", M.rename_tab)
events.make_event("vnix:rename-pane", M.rename_pane)

events.make_event(
  "vnix:trigger-rename",
  ---Trigger rename UI
  ---@param win Window
  ---@param pane Pane
  ---@param kind RenameTarget?
  function(win, pane, kind)
    if not kind then
      kind = "pane"
    end

    require("vnix.rpc").dispatch(win, pane, {
      type = "rename",
      id = 0,
      timestamp = "",
      return_to = 0,
      data = {
        kind = kind,
      },
    })
  end
)

events.make_event(
  "vnix:handle-rename",
  ---callback
  ---@param win Window
  ---@param pane Pane
  ---@param data UIMessageRenameRespData
  function(win, pane, data)
    local active_pane = vnix.runtime.active_pane
    if not active_pane then
      error("No active pane found!")
    end

    local all = data.kind == "all"

    if data.kind == "workspace" or all then
      M.rename_workspace(win, pane, active_pane.workspace, data.name, all)
    end

    if data.kind == "tab" or all then
      M.rename_tab(win, pane, active_pane.tab_id, data.name, all)
    end

    if data.kind == "pane" or all then
      M.rename_pane(win, pane, active_pane.id, data.name, all)
    end

    wezterm.emit("vnix:switch-to", active_pane.id)

    if all then
      -- FIXME: It should've been operation limited to new workspace (`init` would do everything)
      wezterm.emit("vnix:state-update", win, "init")
    end
  end
)

return M
