local wezterm = require("wezterm")
local common = require("common")
local t = require("common.time")
local act = wezterm.action
local events = require("vnix.events")
local rpc = require("vnix.rpc")
local mux = require("vnix.mux")
local state = require("vnix.state")
local vnix = wezterm.GLOBAL.vnix

---@class VnixprocsActionsMod
local M = {} ---@type VnixprocsActionsMod

wezterm.on(
  "vnix:procs",
  ---cb
  ---@param win Window
  ---@param pane Pane
  function(win, pane)
    local procs = {}

    local workspace = state:find_workspace_by_name(
      vnix.runtime.active_pane and vnix.runtime.active_pane.workspace or ""
    )

    if workspace and workspace.procs then
      procs = workspace.procs
    end

    ---@type UIMessageProcsReq
    local payload = {
      id = 0,
      type = "procs",
      return_to = 0,
      data = procs,
      workspace = "",
      pid = wezterm.procinfo.pid(),
    }

    rpc.dispatch(win, pane, payload)
  end
)

---@param proc VnixProcRuntime
local function kill_proc(proc)
  local tab = mux.find_tab(proc.tab_id)
  if tab then
    local proc_pane = tab:active_pane()
    if proc_pane then
      wezterm.run_child_process({
        "vnix-wezterm",
        "kill-pane",
        tostring(proc_pane:pane_id()),
      })
    end
  end
end

events.make_event(
  "vnix:proc-run",
  ---@param win Window
  ---@param pane Pane
  ---@param subject VnixProcRuntime
  ---@diagnostic disable-next-line: unused-local
  function(win, pane, subject)
    if not subject then
      return
    end

    local workspace = subject.workspace
    local mux_win = mux.find_win(workspace)
    if not mux_win then
      error("Failed to acquire workspace!")
    end

    ---@type MuxTab?
    local tab

    if subject.tab_id then
      kill_proc(subject)
    end

    _, tab = mux.create_tab({
      name = subject.title,
      pane = {
        name = subject.title,
        cwd = subject.cwd,
        args = wezterm.shell_split(subject.cmd),
      },
    }, mux_win, #mux_win:tabs() - 1)

    if tab then
      state:update_proc(subject, tab, state:find_workspace_by_name(workspace))
    end

    vnix.procs_last_refresh = vnix.procs_last_refresh - 100
    wezterm.emit("update-status", win, pane)
  end
)

events.make_event(
  "vnix:proc-stop",
  ---@param win Window
  ---@param pane Pane
  ---@param subject VnixProcRuntime
  ---@diagnostic disable-next-line: unused-local
  function(win, pane, subject)
    if not subject then
      return
    end

    local workspace = subject.workspace
    local mux_win = mux.find_win(workspace)
    if not mux_win then
      error("Failed to acquire workspace!")
    end

    if subject.tab_id then
      kill_proc(subject)
    end

    state:update_proc(subject, nil, state:find_workspace_by_name(workspace))
    vnix.procs_last_refresh = vnix.procs_last_refresh - 100
    wezterm.emit("update-status", win, pane)
  end
)

function M.refresh_procs()
  vnix.procs_last_refresh = vnix.procs_last_refresh or 0
  local now = t.now_unix()

  if vnix.ui_req.type ~= "procs" or (now - vnix.procs_last_refresh) < 1 then
    return
  end

  vnix.procs_last_refresh = t.now_unix()
  local workspace = state:find_workspace_by_name(vnix.ui_req.workspace)

  if not workspace then
    return
  end

  local procs = {}
  for _, v in pairs(workspace.procs or {}) do
    ---@type MuxTab?
    local tab = nil

    if v.tab_id then
      tab = mux.find_tab(v.tab_id)
    end

    local proc = state:update_proc(v, tab, workspace, true)
    if proc then
      table.insert(procs, proc)
    end
  end

  vnix.ui_req.data = procs
  vnix.ui_req.timestamp = t.iso_timestamp()
  state:_save()
  rpc.replay(vnix.ui_req)
end

return M
