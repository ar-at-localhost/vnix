local wezterm = require("wezterm")
local rpc = require("vnix.rpc")

wezterm.on(
  "vnix:org-tasks",
  ---cb
  ---@param win Window
  ---@param pane Pane
  function(win, pane)
    ---@type UIMessageOrgReq
    local payload = {
      id = 0,
      type = "org",
      return_to = 0,
      data = nil,
      pid = wezterm.procinfo.pid(),
    }

    rpc.dispatch(win, pane, payload)
  end
)
