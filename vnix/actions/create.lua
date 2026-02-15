--TODO: Activate
local wezterm = require("wezterm")
local rpc = require("vnix.rpc")
local mux = require("vnix.mux")
local state = require("vnix.state")

wezterm.on(
  "vnix:create",
  ---Callback
  ---@param win Window
  ---@param pane Pane
  function(win, pane)
    rpc.dispatch(win, pane, {
      id = 0,
      return_to = 0,
      type = "create",
      data = nil,
    })
  end
)

wezterm.on(
  "vnix:create-workspace",
  ---cb
  ---@param win Window
  ---@param pane Pane
  ---@param data VnixWorkspace
  ---@diagnostic disable-next-line: unused-local
  function(win, pane, data)
    mux.create_workspace(data, function(workspace)
      state.save_worksapce(data, workspace)
    end)
  end
)
