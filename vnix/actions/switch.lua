local wezterm = require("wezterm")
local vnix_mux = require("vnix.mux")
local rpc = require("vnix.rpc")
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

wezterm.on(
  "vnix:switch-to",
  ---cb
  ---@param id? number
  ---@param cb? fun(win?: Window)
  function(id, cb)
    local ok, err = pcall(function()
      local state = require("vnix.state")
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

        print(pane)
        gui_window:perform_action(wezterm.action.ActivateTab(tab_idx), active_pane)
        gui_window:perform_action(wezterm.action.ActivatePaneByIndex(pane.idx or 0), active_pane)

        wezterm.time.call_after(0, function()
          if cb then
            cb(gui_window)
          else
            wezterm.emit("vnix:state-update", gui_window, "effective")
          end
        end)
      else
        error("Unable to find pane!")
      end
    end)

    if not ok then
      wezterm.log_error("(vnix:switch-to)", err)
    end
  end
)
