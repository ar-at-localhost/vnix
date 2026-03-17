local wezterm = require("wezterm")
local common = require("common")
local act = wezterm.action
local events = require("vnix.events")
local rpc = require("vnix.rpc")
local mux = require("vnix.mux")
local state = require("vnix.state")
local t = require("common.time")
local vnix = wezterm.GLOBAL.vnix

wezterm.on(
  "vnix:procs",
  ---cb
  ---@param win Window
  ---@param pane Pane
  function(win, pane)
    ---@type UIMessageProcsReq
    local payload = {
      id = 0,
      type = "procs",
      return_to = 0,
      data = nil,
      pid = wezterm.procinfo.pid(),
    }

    rpc.dispatch(win, pane, payload)
  end
)

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

    -- Lock status refresh
    vnix.procs_last_refresh = t.now_unix()

    pcall(function()
      if subject.tab_id then
        local tab = mux.find_tab(subject.tab_id)
        if tab then
          local proc_pane = tab:active_pane()
          if pane then
            wezterm.run_child_process({
              "vnix-wezterm",
              "kill-pane",
              tostring(proc_pane:pane_id()),
            })
          end
        end
      end

      local _, tab = mux.create_tab({
        name = subject.title,
        pane = {
          name = subject.title,
          cwd = subject.cwd,
          args = wezterm.shell_split(subject.cmd),
        },
      }, mux_win, subject.workspace, #mux_win:tabs())

      state.update_proc(subject, tab, state.find_workspace_by_name(workspace), true)
    end)

    -- Switch to vnix workspace for user interaction
    win:perform_action(
      act.SwitchToWorkspace({
        name = common.vnix_token,
      }),
      pane
    )

    win:perform_action(act.ActivateTab(0), pane)
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

    -- Lock status refresh
    vnix.procs_last_refresh = t.now_unix()

    pcall(function()
      if subject.tab_id then
        local tab = mux.find_tab(subject.tab_id)
        if tab then
          local proc_pane = tab:active_pane()
          if pane then
            wezterm.run_child_process({
              "vnix-wezterm",
              "kill-pane",
              tostring(proc_pane:pane_id()),
            })
          end
        end
      end
    end)

    state.update_proc(subject, nil, state.find_workspace_by_name(workspace), true)

    -- Switch to vnix workspace for user interaction
    win:perform_action(
      act.SwitchToWorkspace({
        name = common.vnix_token,
      }),
      pane
    )

    win:perform_action(act.ActivateTab(0), pane)
  end
)

events.make_event(
  "vnix:procs-refresh",
  ---@param win Window
  ---@param pane Pane
  ---@param subject VnixProcRuntime
  ---@diagnostic disable-next-line: unused-local
  function(win, pane, subject)
    local proc_last_refresh = vnix.procs_last_refresh

    if proc_last_refresh then
      local now = t.now_unix()
      local diff = now - proc_last_refresh

      if diff < 5 then
        return
      end
    end

    vnix.procs_last_refresh = t.now_unix()

    local mux_win = mux.find_win(common.vnix_token)
    if not mux_win then
      error("Failed to acquire workspace!")
    end

    local tabs = mux_win:tabs()
    for _, tab in ipairs(tabs) do
      if tab:get_title() ~= common.vnix_token then
        local proc, _, _, workspace = state.find_proc_by_tab_id(tab:tab_id())
        if proc then
          state.update_proc(proc, tab, workspace, false)
        end
      end
    end

    state.save()
  end
)
