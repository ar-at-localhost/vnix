local wezterm = require("wezterm")
local rpc = require("vnix.rpc")
local events = require("vnix.events")

events.make_event(
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
      workspace = "",
      data = "tasks",
      pid = wezterm.procinfo.pid(),
    }

    rpc.dispatch(win, pane, payload)
  end
)

events.make_event(
  "vnix:org-files",
  ---cb
  ---@param win Window
  ---@param pane Pane
  function(win, pane)
    ---@type UIMessageOrgReq
    local payload = {
      id = 0,
      type = "org",
      workspace = "",
      return_to = 0,
      data = "files",
      pid = wezterm.procinfo.pid(),
    }

    rpc.dispatch(win, pane, payload)
  end
)
