local wezterm = require("wezterm")
local time = require("common.time")
local act = wezterm.action
local vnix = wezterm.GLOBAL.vnix

local M = {}

---UI Dispatch action
---@param win Window
---@param pane Pane
---@param args UIMessageReqBase
function M.dispatch(win, pane, args)
  -- Store current pane index for potential return navigation
  ---@diagnostic disable-next-line: unused-local
  local active_pane = vnix.activity.active_pane
  if not active_pane then
    return
  end

  -- Prepare action data
  ---@type UIMessageReqBase?
  local action_data = args or nil

  if action_data then
    action_data.id = vnix.ui_next_req
    action_data.timestamp = time.iso_timestamp()
    action_data.return_to = active_pane.id or 1
    vnix.ui_next_req = vnix.ui_next_req + 1

    wezterm.emit("vnix:ui-req", action_data)
  end

  -- Switch to __vnix__ workspace for user interaction
  win:perform_action(
    act.SwitchToWorkspace({
      name = "__vnix__",
    }),
    pane
  )
end

--- Parse the incoming message from Nvim RPC
---@param win Window
---@param pane Pane
---@param data string
function M.parse(win, pane, data)
  ---@type UIMessageRespBase
  local parsed = wezterm.json_parse(data)
  if not parsed then
    error("JSON parse returned nil")
  end

  -- Validate required fields
  if not parsed.type then
    error("Invalid type of RPC message recieved.")
  end

  if parsed.type == "create" then
    ---@cast parsed UIMessageCreateResp
    if parsed.data and parsed.data.type == "workspace" then
      wezterm.emit("vnix:create-workspace", parsed.data.spec)
    elseif parsed.data and parsed.data.type == "tab" then
      --TODO: Create tab logic
    end
  end

  if parsed.type == "debug" then
    ---@cast parsed UIMessageDebugResp
    return wezterm.emit("vnix:debug-run-lua", win, pane, parsed)
  end

  --- Switch Message Type
  if parsed.type == "switch" or parsed.type == "inspect" then
    ---@cast parsed UIMessageSwitchResp
    return wezterm.emit("vnix:switch-to", parsed.data)
  end

  --- Ready Message Type
  if parsed.type == "launch" then
    ---@cast parsed UIMessageSwitchResp
    return wezterm.emit("vnix:ui-setup")
  end
end

return M
