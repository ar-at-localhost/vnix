local wezterm = require("wezterm")
local state = require("vnix.state.state")
local time = require("vnix.utils.time")
local log = require("vnix.utils.log")
local pane_utils = require("vnix.utils.pane_utils")
local vnix = wezterm.GLOBAL.vnix

local M = {}

local function clear_focus_for_other_panes(current_pane, current_state)
  if not current_pane or not current_state then
    return
  end

  for _, pane_state in ipairs(current_state) do
    if pane_state and pane_state ~= current_pane then
      -- Clear focus flags for panes in the same tab
      if pane_state._tab_id == current_pane._tab_id then
        pane_state.focus_tab = false
      end

      -- Clear focus flags for panes in the same workspace
      if pane_state._workspace_id == current_pane._workspace_id then
        pane_state.focus_workspace = false
      end

      -- Clear global focus
      pane_state.focused = false
    end
  end
end

---Update focus state
---@param current_pane? PaneState
---@param last_pane? PaneState
---@param current_state? PaneState[]
---@param context any
---@return any
---@return any
---@return any
function M.update_focus(current_pane, last_pane, current_state, context)
  if not context then
    context = "p"
  end

  local now = os.time()
  local today = time.format_date(now)
  local time_tracker = vnix.activity.tt
  local tts = vnix.activity.tts or now
  local tt = math.max(0, now - tts)

  if
    current_state
    and ((current_pane and current_pane.ttd ~= today) or (last_pane and last_pane.ttd ~= today))
  then
    current_state = M.reset_time_tracker(current_state)
  end

  if current_pane then
    -- Clear focus flags for all other panes in the same tab/workspace first
    clear_focus_for_other_panes(current_pane, current_state)

    -- Always set focus flags for the current pane
    current_pane.focus_tab = true
    current_pane.focus_workspace = true
    current_pane.focused = true

    current_pane.tt = current_pane.tt or 0
    current_pane.ttb = current_pane.ttb or 0
  end

  if last_pane then
    if context == "t" then
      -- When switching tabs, keep the focus_tab flag for the last pane in that tab
      -- This helps remember the last active pane per tab
      last_pane.focus_tab = true
    end

    if context == "w" then
      -- When switching workspaces, keep the focus_workspace flag for the last pane in that workspace
      -- This helps remember the last active pane per workspace
      last_pane.focus_workspace = true
    end

    if time_tracker then
      last_pane.tt = (last_pane.tt or 0) + tt
    else
      last_pane.ttb = (last_pane.ttb or 0) + tt
    end
  end

  if current_state then
    state.save(current_state)
  end

  vnix.activity.tts = now
  return current_pane, last_pane, current_state
end

---Reset time tracker
---@param all_panes PaneState[]
---@return table
function M.reset_time_tracker(all_panes)
  local now = os.time()
  vnix.activity.tts = now
  local _ = time.format_date()
  local ttd = type(_) == "string" and _ or tostring(_)

  for _, v in ipairs(all_panes) do
    v.tt = 0
    v.ttb = 0
    v.ttd = ttd
  end

  return state.save_and_return(all_panes)
end

function M.reset_pane_sizes(win)
  local tab = win:active_tab()
  local cm = ", aborting pane size updates."

  if not tab then
    return log.log("warn", "could not find current tab" .. cm)
  end

  local panes = tab:panes_with_info()
  if not panes or not #panes then
    return log.log("warn", "could not obtain panes info" .. cm)
  end

  local state_panes = state.get()
  if not state_panes or not #state_panes then
    return log.log("warn", "could not obtain state" .. cm)
  end

  local filtered = {}
  for _, v in ipairs(state_panes) do
    local w = win:active_workspace()
    local t = tab:get_title()

    if v.workspace == w and v.tab == t then
      table.insert(filtered, v)
    end
  end

  log.log("info", "Resizing " .. tostring(#filtered) .. " panes...")
  for _, sp in ipairs(filtered) do
    for pi, p in ipairs(panes) do
      local pid = p.pane:pane_id()
      log.log("info", "resize pair: (" .. tostring(pid) .. "," .. tostring(sp._pane_id) .. ")")
      if pid == sp._pane_id then
        pane_utils.resolve_size(win, p, sp)

        log.log(
          "info",
          "new pane size: (" .. tostring(sp.size.width) .. "x" .. tostring(sp.size.height) .. ")"
        )

        table.remove(panes, pi)
        break
      end
    end
  end

  state.save(state_panes)
end

return M
