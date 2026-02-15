local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local misc = require("vnix.utils.misc")
local time = require("vnix.utils.time")
local vnix = wezterm.GLOBAL.vnix

local M = {}

---Get current state
---@return PaneState[]
function M.get()
  if not vnix.state then
    log.log("WARN", "vnix: Invalid state detected, initializing empty state")
    vnix.state = {}
  end

  local flat_state = misc.keys_to_num(vnix.state)
  local state = {}

  for _, v in ipairs(flat_state) do
    table.insert(state, v)
  end

  return state
end

---@param state? PaneState[]
function M.save_and_return(state)
  return M.save(state)
end

function M.save(state)
  if not state then
    state = M.get()
  end

  vnix.state = state

  local copy = {}
  local total_time_today, total_non_break_today, total_break_today = table.unpack({ 0, 0, 0 })

  -- Safely iterate through state with error handling
  local ok, err = pcall(function()
    for _, p in ipairs(misc.keys_to_num(state)) do
      local pcopy = {
        name = p.name or "",
        workspace = p.workspace or "",
        tab = p.tab or "",
        cwd = p.cwd or "",
        args = p.args or nil,
        args_mode = p.args_mode or nil,
        lazy = p.lazy or false,
        env = p.env or nil,
        size = p.size or { percent = 100, relative = 1, width = 0, height = 0 },
        bottom = p.bottom or nil,
        right = p.right or nil,
        top = p.top or nil,
        left = p.left or nil,
        first = p.first or nil,
        focus_tab = p.focus_tab or false,
        focus_workspace = p.focus_workspace or false,
        tt = p.tt or 0,
        ttb = p.ttb or 0,
        ttd = p.ttd or os.date("%x"),
        extras = p.extras or nil,
      }

      table.insert(copy, pcopy)

      total_time_today = total_time_today + pcopy.tt + pcopy.ttb
      total_non_break_today = total_non_break_today + pcopy.tt
      total_break_today = total_break_today + pcopy.ttb
    end
  end)

  vnix.activity.total_time_today = total_time_today
  vnix.activity.total_non_break_today = total_non_break_today
  vnix.activity.total_break_today = total_break_today

  if not ok then
    log.log("ERROR", "vnix: Error processing state for save: " .. tostring(err))
    return state
  end

  pcall(function()
    local vnixCommon = require("vnix-common")
    vnixCommon.write_json(vnix.state_file, copy)
    vnixCommon.write_json(vnix.activity_file, vnix.activity)
  end)

  return M.get()
end

---Find the current pane within the state registry
---@param win Window
---@param pane Pane
---@param raise_error? boolean
---@return PaneState?
---@return number?
---@return State?
function M.find_pane(win, pane, raise_error)
  local err

  if not win or not pane then
    err = "vnix: Invalid win or pane provided to find_pane"
    log.log("ERROR", err)

    if raise_error then
      error(err)
    end

    return nil, nil, nil
  end

  local state = M.get()
  if not state then
    err = "vnix: Invalid state encountered in find_pane"
    log.log("ERROR", err)
    if raise_error then
      error(err)
    end
    return nil, nil, nil
  end

  local ok, current_workspace_id, current_tab_id, current_pane_id = pcall(function()
    local workspace_id = win:active_workspace()
    local tab = win:active_tab()

    if not tab then
      error("No active tab")
    end

    local tab_id = tab:tab_id()
    local pane_id = pane:pane_id()
    return workspace_id, tab_id, pane_id
  end)

  if not ok then
    err = "vnix: Error accessing WezTerm objects: " .. tostring(current_workspace_id)
    log.log("ERROR", err)

    if raise_error then
      error(err)
    end

    return nil, nil, state
  end

  for i, s in ipairs(state) do
    if
      s
      and s["_workspace_id"] == current_workspace_id
      and s["_tab_id"] == current_tab_id
      and s["_pane_id"] == current_pane_id
    then
      return s, i, state
    end
  end

  err = "vnix: Could not find current pane in state due to uknown issue => "
    .. tostring(current_workspace_id)
    .. " "
    .. tostring(current_tab_id)
    .. " "
    .. tostring(current_pane_id)

  log.log("ERROR", err)
  if raise_error then
    error(err)
  end

  return nil, nil, state
end

return M
