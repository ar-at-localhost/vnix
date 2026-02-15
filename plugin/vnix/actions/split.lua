local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local state = require("vnix.state.state")
local state_utils = require("vnix.state.state_utils")
local vnix = wezterm.GLOBAL.vnix

---Assign indexes to panes
---@param win Window
local function assign_indexes(win)
  log.log("INFO", "Assigning indexes to panes...")

  local _, err = pcall(function()
    local tab = win:active_tab()

    if not tab then
      error("No active tab!")
    end

    ---@type PanesWithInfo[]
    local panes = tab:panes_with_info()
    for _, v in ipairs(panes) do
      local p = v.pane
      ---@diagnostic disable-next-line: unused-local
      local ps, _, __ = state.find_pane(win, p)

      if ps then
        ps._wez_pane_index = v.index
      end
    end
  end)

  if err then
    log.log("ERROR", "Error while assigning indexes " .. err)
  end
end

---Assign indexes to panes
---@param tab MuxTab
---@param pane_state PaneState
local function assign_index(tab, pane_state)
  log.log("INFO", "Assigning indexes to panes...")

  local _, err = pcall(function()
    ---@type PanesWithInfo[]
    local panes = tab:panes_with_info()
    for _, v in ipairs(panes) do
      if v.pane:pane_id() == pane_state._pane_id then
        pane_state._wez_pane_index = v.index
      end
    end
  end)

  if err then
    log.log("ERROR", "Error while assigning indexes " .. err)
  end
end

local function split(win, pane, dir)
  -- Validate input parameters
  if not win or not pane then
    log.log("ERROR", "vnix: Invalid win or pane provided to split")
    return false
  end

  if dir ~= "bottom" and dir ~= "right" then
    log.log("ERROR", "vnix: Invalid split direction: " .. tostring(dir))
    return false
  end

  local action_params = { domain = "CurrentPaneDomain", size = 0.5 }
  local action = {}
  if dir == "bottom" then
    action["SplitVertical"] = action_params
  else
    action["SplitHorizontal"] = action_params
  end

  local source_pane_state, source_pane_state_index = state.find_pane(win, pane)

  if not source_pane_state or not source_pane_state_index then
    log.log("WARN", "vnix: Cannot find source pane for split")
    return false
  end

  -- Get current state and validate
  local all_panes = state.get()
  if not all_panes then
    log.log("ERROR", "vnix: Cannot get current state for split")
    return false
  end

  -- Perform the split action with error handling
  local split_ok, split_err = pcall(function()
    win:perform_action(action, pane)
  end)

  if not split_ok then
    log.log("ERROR", "vnix: Failed to perform split action: " .. tostring(split_err))
    return false
  end

  -- Get the new pane with error handling
  local new_pane, new_pane_id
  local pane_ok, pane_err = pcall(function()
    new_pane = win:active_pane()
    new_pane_id = new_pane:pane_id()
  end)

  if not pane_ok or not new_pane or not new_pane_id then
    log.log("ERROR", "vnix: Failed to get new pane after split: " .. tostring(pane_err))
    return false
  end

  -- Refresh state after split
  all_panes = state.get()
  if not all_panes then
    log.log("ERROR", "vnix: Cannot refresh state after split")
    return false
  end

  -- Construct the state for the newly created pane
  local new_pane_state = {
    _pane_id = new_pane_id,
    _tab_id = source_pane_state._tab_id,
    _tab_index = source_pane_state._tab_index,
    _workspace_id = source_pane_state._workspace_id,
    args = {},
    cwd = source_pane_state.cwd or vnix.user_home,
    nav_focus = true,
    name = tostring(new_pane_id),
    tab = source_pane_state.tab,
    workspace = source_pane_state.workspace,
  }

  -- Calculate the index where the new pane will be inserted (1-based)
  local new_pane_index = #all_panes + 1

  -- Link the source pane to the newly created pane for restoration purposes
  source_pane_state[dir] = new_pane_index
  source_pane_state.first = source_pane_state.first or dir

  -- Add back-references to the new pane (top/left)
  -- No circular reference check needed since we only set forward refs (right/bottom) on parents
  -- and back-refs (top/left) on children, which naturally prevents cycles
  if dir == "bottom" then
    new_pane_state.top = source_pane_state_index
  elseif dir == "right" then
    new_pane_state.left = source_pane_state_index
  end

  -- Add the new pane to the state
  table.insert(all_panes, new_pane_state)
  vnix.activity.cp_id = new_pane_index
  state_utils.update_focus(new_pane_state, source_pane_state, all_panes)
  state_utils.reset_pane_sizes(win)
  return true
end

wezterm.on("vnix:split_pane_bottom", function(win, pane)
  local ok = split(win, pane, "bottom")
  if not ok then
    log.log("ERROR", "vnix: Bottom split operation failed")
  end
end)

wezterm.on("vnix:split_pane_right", function(win, pane)
  local ok = split(win, pane, "right")
  if not ok then
    log.log("ERROR", "vnix: Right split operation failed")
  end
end)

-- Additional event handlers for test compatibility
wezterm.on("vnix:split-vertical", function(win, pane)
  log.log("INFO", "vnix: Received split-vertical event")
  local ok = split(win, pane, "bottom")
  if not ok then
    log.log("ERROR", "vnix: Vertical split operation failed")
  else
    log.log("INFO", "vnix: Vertical split operation succeeded")
  end
end)

wezterm.on("vnix:split-horizontal", function(win, pane)
  log.log("INFO", "vnix: Received split-horizontal event")
  local ok = split(win, pane, "right")
  if not ok then
    log.log("ERROR", "vnix: Horizontal split operation failed")
  else
    log.log("INFO", "vnix: Horizontal split operation succeeded")
  end
end)

-- Export module for testing
-- FIXME: Cleanup or move to core
local M = {}
M.split = split
M.assign_index = assign_index
M.assign_indexes = assign_indexes
return M
