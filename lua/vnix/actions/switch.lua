local wezterm = require("wezterm")
local vnix_mux = require("vnix.mux")
local rpc = require("vnix.rpc")
local events = require("vnix.events")
local state = require("vnix.state")

---@type VNixGlobal
local vnix = wezterm.GLOBAL.vnix

wezterm.on("vnix:switch", function(win, pane)
  -- Validate input parameters
  if not win or not pane or not vnix then
    return
  end

  rpc.dispatch(win, pane, {
    id = 0,
    return_to = 0,
    type = "switch",
    data = nil,
  })
end)

events.make_event(
  "vnix:switch-to-workspace",
  ---@param workspace string
  function(workspace)
    local w = state.find_workspace_by_name(workspace)

    local pane = vnix.runtime.active_pane

    if w then
      pane = vnix.runtime.focus[w.name] or w.tabs[1].pane
    end

    wezterm.emit("vnix:switch-to", pane and pane.id or nil)
  end
)

events.make_event(
  "vnix:switch-to-tab",
  ---@param tab_id number
  function(tab_id)
    local pane = vnix.runtime.active_pane

    if pane then
      local workspace = state.find_workspace_by_name(pane.workspace)
      if workspace then
        local tab = state.find_tab_by_id(workspace, tab_id)
        if tab then
          pane = vnix.runtime.focus[workspace.name .. "." .. tab.name] or tab.pane
        end
      end
    end

    wezterm.emit("vnix:switch-to", pane and pane.id or nil)
  end
)

wezterm.on(
  "vnix:switch-to",
  ---cb
  ---@param id? number
  ---@param cb? fun(ok: boolean, win?: Window, err?: string)
  function(id, cb)
    local ok, err = pcall(function()
      local pane, tab, tab_idx, workspace = state.find_pane_by_id(id)

      if pane and tab and workspace then
        local gui_window = vnix_mux.resolve_gui_window()
        if not gui_window then
          error("Unable to acquire GUI Window.")
        end

        local active_pane = gui_window:active_pane()
        if not active_pane then
          error("Unable to acquire active pane.")
          return
        end

        gui_window:perform_action(
          wezterm.action.SwitchToWorkspace({
            name = workspace.name,
          }),
          active_pane
        )

        gui_window:perform_action(wezterm.action.ActivateTab(tab_idx - 1), active_pane)
        gui_window:perform_action(wezterm.action.ActivatePaneByIndex(pane.idx or 0), active_pane)

        wezterm.time.call_after(0, function()
          if cb then
            cb(true, gui_window)
          else
            wezterm.emit("vnix:state-update", gui_window, "effective")
          end
        end)
      else
        if cb then
          cb(false, nil, "Unable to find pane!")
        else
          error("Unable to find pane!")
        end
      end
    end)

    if not ok then
      wezterm.log_error("(vnix:switch-to)", err)
    end
  end
)
