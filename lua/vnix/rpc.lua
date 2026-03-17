local wezterm = require("wezterm")
local time = require("common.time")
local fs = require("common.fs")
local act = wezterm.action
local vnix = wezterm.GLOBAL.vnix

local M = {}

---UI Dispatch remote cmd
---@param cmd string
function M.dispatch_cmd(cmd)
  local full_cmd = string.format(
    "vnix-nvim --server %s --remote-send \"<cmd>Vnix %s<cr>\"",
    vnix.runtime.sock_path,
    cmd
  )

  local cmd_table = wezterm.shell_split(full_cmd)
  wezterm.background_child_process(cmd_table)
end

---UI Get status from nvim
---@return VnixStatus?
function M.get_status()
  return fs.read_json(string.format("%s/status.json", vnix.vnix_dir))
end

---UI Dispatch action
---@param win Window
---@param pane Pane
---@param args UIMessageReqBase
function M.dispatch(win, pane, args)
  -- Store current pane index for potential return navigation
  ---@diagnostic disable-next-line: unused-local
  local active_pane = vnix.runtime.active_pane
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

  vnix.ui_req = args

  -- Switch to vnix workspace for user interaction
  win:perform_action(
    act.SwitchToWorkspace({
      name = vnix.nvim.pane.workspace,
    }),
    pane
  )

  win:perform_action(act.ActivateTab(0), pane)
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
      wezterm.emit("vnix:create-workspace", win, pane, parsed.data.spec)
    elseif parsed.data and parsed.data.type == "tab" then
      wezterm.emit("vnix:create-tab", win, pane, parsed.data.spec)
    end
  end

  if parsed.type == "debug" then
    ---@cast parsed UIMessageDebugResp
    return wezterm.emit("vnix:debug-run-lua", win, pane, parsed)
  end

  --- Ready Message Type
  if parsed.type == "launch" then
    ---@cast parsed UIMessageSwitchResp
    return wezterm.emit("vnix:ui-setup")
  end

  --- Ready Message Type
  if parsed.type == "rename" then
    ---@cast parsed UIMessageRenameResp
    return wezterm.emit("vnix:handle-rename", win, pane, parsed.data)
  end

  --- Switch Message Type
  if parsed.type == "switch" then
    ---@cast parsed UIMessageSwitchResp

    if parsed.data and parsed.data.kind == "tab" then
      return wezterm.emit("vnix:switch-to-tab", parsed.data.id)
    elseif parsed.data and parsed.data.kind == "workspace" then
      return wezterm.emit("vnix:switch-to-workspace", parsed.data.id)
    else
      return wezterm.emit("vnix:switch-to", parsed.data.id)
    end
  end

  --- Procs messages
  if parsed.type == "procs" then
    ---@cast parsed UIMessageProcsResp
    if not parsed.data or not parsed.data.action or parsed.data.action == "close" then
      return wezterm.emit("vnix:switch-to")
    elseif parsed.data and parsed.data.action == "run" then
      wezterm.emit("vnix:proc-run", win, pane, parsed.data.subject)
    elseif parsed.data and parsed.data.action == "stop" then
      wezterm.emit("vnix:proc-stop", win, pane, parsed.data.subject)
    end
  end
end

return M
