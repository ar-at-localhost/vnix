local wezterm = require("wezterm")
local rpc = require("vnix.rpc")

wezterm.on(
  "vnix:debug",
  ---cb
  ---@param win Window
  ---@param pane Pane
  function(win, pane)
    ---@type UIMessageDebugReq
    local payload = {
      id = 0,
      type = "debug",
      return_to = 0,
      data = nil,
      pid = wezterm.procinfo.pid(),
    }

    rpc.dispatch(win, pane, payload)
  end
)

wezterm.on(
  "vnix:debug-run-lua",
  ---cb
  ---@param win Window
  ---@param pane Pane
  ---@param data UIMessageDebugResp
  function(win, pane, data)
    local ok = false
    local result = ""

    if not data or not data.data or data.data.type ~= "run" then
      return
    end

    local src = data.data.lua
    local chunk, err = load(src)

    if not chunk then
      ok = false
      result = "Syntax error: " .. tostring(err)
    else
      ok, result = pcall(chunk)
    end

    rpc.dispatch(win, pane, {
      id = 0,
      type = "debug",
      timestamp = "",
      return_to = 0,
      data = {
        id = data.id,
        ok = ok,
        result = result,
      },
    })
  end
)
