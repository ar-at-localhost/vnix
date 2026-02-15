local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local time = require("vnix.utils.time")
local act = wezterm.action
local vnix = wezterm.GLOBAL.vnix
local state = require("vnix.state.state")

local M = {}

---UI Dispatch action
---@param win Window
---@param pane Pane
---@param args UIMessageReqBase
function M.dispatch(win, pane, args)
  -- Check if ui is running
  if vnix.no_nvim_ui then
    log.log("ERROR", "vnix: UI not available")
    return
  end

  -- Store current pane index for potential return navigation
  ---@diagnostic disable-next-line: unused-local
  local active_pane, pane_index, __ = state.find_pane(win, pane)
  if active_pane then
    vnix.current_pane_index = pane_index or 1
  end

  -- Prepare action data
  ---@type UIMessageReqBase?
  local action_data = args or nil

  if action_data then
    action_data.id = vnix.ui_next_req
    action_data.timestamp = time.iso_timestamp()
    action_data.return_to = pane_index or 1
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

  log.log("INFO", "vix: dispatched vnix:ui-req | " .. wezterm.json_encode(action_data))
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

  --- Ready Message Type
  if parsed.type == "launch" then
    ---@cast parsed UIMessageSwitchResp
    return wezterm.emit("vnix:ui-setup")
  end

  --- Switch Message Type
  if parsed.type == "switch" or parsed.type == "inspect" then
    ---@cast parsed UIMessageSwitchResp
    return wezterm.emit("vnix:switch-to", win, pane, parsed.data)
  end

  if parsed.type == "timesheet" then
    return wezterm.emit("vnix:tt-action", win, pane, parsed)
  end
end

return M
