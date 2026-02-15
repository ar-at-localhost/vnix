local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local state = require("vnix.state.state")
local state_utils = require("vnix.state.state_utils")
local vnix = wezterm.GLOBAL.vnix
local split = require("vnix.actions.split")

wezterm.on("vnix:kill", function(win, pane)
  -- Validate input parameters
  if not win or not pane then
    log.log("ERROR", "vnix: Invalid win or pane provided to kill")
    return
  end

  local current, current_index = state.find_pane(win, pane)

  if not current or not current_index then
    log.log("WARN", "vnix: Cannot find pane to kill in state")
    return
  end

  -- Safely perform the close action with error handling
  local close_ok, close_err = pcall(function()
    win:perform_action({ CloseCurrentPane = { confirm = false } }, pane)
  end)

  if not close_ok then
    log.log("ERROR", "vnix: Failed to close pane: " .. tostring(close_err))
    return
  end

  local all_panes = state.get()
  if not all_panes or #all_panes == 0 then
    log.log("WARN", "vnix: No panes in state to modify")
    return
  end

  -- Validate current_index is within bounds
  if current_index < 1 or current_index > #all_panes then
    log.log("ERROR", "vnix: Invalid pane index for removal: " .. current_index)
    return
  end

  -- Remove the pane that was just closed from the state
  table.remove(all_panes, current_index)
  split.assign_indexes(win)
  local new_pane, new_pane_index, _ = state.find_pane(win, win:active_pane())
  vnix.activity.cp_id = new_pane_index or 1
  state_utils.update_focus(new_pane, nil, all_panes)

  -- Adjust references in remaining panes (using consistent 1-based indexing)
  for _, s in ipairs(all_panes) do
    if s then
      -- If this pane's 'right' split referenced the removed pane,
      -- inherit the removed pane's splits
      if s.right and s.right == current_index then
        s.right = current.right
        if not s.right and current.bottom then
          s.bottom = current.bottom
          s.first = "bottom"
        elseif s.right then
          s.first = s.first or "right"
        end
      end

      -- If this pane's 'bottom' split referenced the removed pane,
      -- inherit the removed pane's splits
      if s.bottom and s.bottom == current_index then
        s.bottom = current.bottom
        if not s.bottom and current.right then
          s.right = current.right
          s.first = "right"
        elseif s.bottom then
          s.first = s.first or "bottom"
        end
      end

      -- Decrement indices for splits that reference panes after the removed one
      if s.right and s.right > current_index then
        s.right = s.right - 1
      end

      if s.bottom and s.bottom > current_index then
        s.bottom = s.bottom - 1
      end
    end
  end

  -- Update focus tracking if the killed pane was focused
end)
