local state = require("vnix.state.state")
local log = require("vnix.utils.log")

local M = {}

-- Finds the parent of a given pane in the state tree.
-- A parent is a pane that has the given pane_id as its 'right' or 'bottom' split.
local function find_parent_pane(all_panes, pane_id)
  if not pane_id then
    return nil, nil
  end
  for id, p_state in ipairs(all_panes) do
    if p_state and (p_state.right == pane_id or p_state.bottom == pane_id) then
      return p_state, id
    end
  end
  return nil, nil
end

function M.query_pane_in_direction(win, pane, direction, focus_setting)
  focus_setting = focus_setting or false

  log.log("DEBUG", "vnix: query_pane_in_direction called with direction: " .. direction)
  -- This function is now fully state-based, using `right` and `bottom` properties.
  local all_panes = state.get()
  local current_pane_state, current_pane_id = state.find_pane(win, pane)

  if not current_pane_state or not current_pane_id then
    log.log("WARN", "vnix: Could not find current pane in state for directional navigation.")
    return nil
  end

  log.log("DEBUG", "vnix: Current pane ID for direction query: " .. current_pane_id)

  -- Direct navigation for Right and Down
  if direction == "Right" then
    if current_pane_state.right then
      log.log("DEBUG", "vnix: Found direct right neighbor: " .. current_pane_state.right)
      local found_id = current_pane_state.right
      return found_id, "p"
    end
  elseif direction == "Down" then
    if current_pane_state.bottom then
      log.log("DEBUG", "vnix: Found direct bottom neighbor: " .. current_pane_state.bottom)
      local found_id = current_pane_state.bottom
      return found_id, "p"
    end
  end

  -- Direct navigation for Left and Up using back-references
  if direction == "Left" then
    if current_pane_state.left then
      log.log("DEBUG", "vnix: Found direct left neighbor: " .. current_pane_state.left)
      local found_id = current_pane_state.left
      return found_id, "p"
    end
  elseif direction == "Up" then
    if current_pane_state.top then
      log.log("DEBUG", "vnix: Found direct top neighbor: " .. current_pane_state.top)
      local found_id = current_pane_state.top
      return found_id, "p"
    end
  end

  -- Indirect/Sibling navigation: if no direct neighbor, find parent and try from there.
  -- e.g., moving Left from a pane that is a 'bottom' split of another.
  local parent_pane_state, parent_pane_id = find_parent_pane(all_panes, current_pane_id)

  log.log(
    "DEBUG",
    "vnix: No direct neighbor found, trying indirect navigation. Parent ID: "
      .. tostring(parent_pane_id)
  )

  if parent_pane_state and parent_pane_id then
    if direction == "Right" then
      if parent_pane_state.right then
        log.log(
          "DEBUG",
          "vnix: Found indirect right neighbor via parent: " .. parent_pane_state.right
        )

        local found_id = parent_pane_state.right
        return found_id, "p"
      end
    elseif direction == "Down" then
      if parent_pane_state.bottom then
        log.log(
          "DEBUG",
          "vnix: Found indirect bottom neighbor via parent: " .. parent_pane_state.bottom
        )

        local found_id = parent_pane_state.bottom
        return found_id, "p"
      end
    elseif direction == "Left" then
      -- Find the pane that has the parent as its 'right' child
      for id, p_state in ipairs(all_panes) do
        if p_state and p_state.right == parent_pane_id then
          log.log("DEBUG", "vnix: Found indirect left neighbor via parent: " .. id)
          local found_id = id
          return found_id, "p"
        end
      end
    elseif direction == "Up" then
      -- Find the pane that has the parent as its 'bottom' child
      for id, p_state in ipairs(all_panes) do
        if p_state and p_state.bottom == parent_pane_id then
          log.log("DEBUG", "vnix: Found indirect up neighbor via parent: " .. id)
          local found_id = id
          return found_id, "p"
        end
      end
    end
  end

  -- Edge Cycling
  -- if parent_pane_state and parent_pane_id then
  if direction == "Right" then
    local found_id, nav_type = M.query_tab(win, pane, 1)

    if found_id then
      log.log("DEBUG", "vnix: Found next tab for edge cycling: " .. found_id)

      return found_id, nav_type
    end
  elseif direction == "Left" then
    local found_id, nav_type = M.query_tab(win, pane, -1)

    if found_id then
      log.log("DEBUG", "vnix: Found previous tab for edge cycling: " .. found_id)

      return found_id, nav_type
    end
  elseif direction == "Up" then
    local found_id, nav_type = M.query_workspace(win, pane, -1)

    if found_id then
      log.log("DEBUG", "vnix: Found previous workspace for edge cycling: " .. found_id)

      return found_id, nav_type
    end
  elseif direction == "Down" then
    local found_id, nav_type = M.query_workspace(win, pane, 1)

    if found_id then
      log.log("DEBUG", "vnix: Found next workspace for edge cycling: " .. found_id)

      return found_id, nav_type
    end
  end

  log.log("DEBUG", "vnix: No target pane found for direction: " .. direction)
  return nil
end

function M.query_tab(win, pane, delta, focus_setting)
  if not focus_setting then
    focus_setting = true
  end

  log.log("DEBUG", "vnix: query_tab called with delta: " .. delta)
  local current_pane_state, _ = state.find_pane(win, pane)
  if not current_pane_state then
    log.log("WARN", "vnix: Could not find current pane in state for tab navigation.")
    return nil
  end

  local all_panes = state.get()
  local tabs_in_workspace = {}
  local ordered_tab_ids = {}

  -- Get all unique tabs in the current workspace, preserving order
  for _, p_state in ipairs(all_panes) do
    if p_state and p_state._workspace_id == current_pane_state._workspace_id then
      if not tabs_in_workspace[p_state._tab_id] then
        tabs_in_workspace[p_state._tab_id] = true
        table.insert(ordered_tab_ids, p_state._tab_id)
      end
    end
  end

  if #ordered_tab_ids <= 1 then
    log.log("DEBUG", "vnix: Not enough tabs in workspace to navigate.")
    return nil
  end

  -- Find index of current tab
  local current_tab_index = -1
  for i, tab_id in ipairs(ordered_tab_ids) do
    if tab_id == current_pane_state._tab_id then
      current_tab_index = i
      break
    end
  end

  if current_tab_index == -1 then
    log.log("DEBUG", "vnix: Could not find current tab index.")
    return nil
  end

  -- Calculate target tab index
  local target_tab_index = (delta == "$" and #ordered_tab_ids)
    or (delta == 0 and 1)
    or ((current_tab_index - 1 + delta + #ordered_tab_ids) % #ordered_tab_ids + 1)

  local target_tab_id = ordered_tab_ids[target_tab_index]
  log.log("DEBUG", "vnix: Target tab ID: " .. target_tab_id)

  -- Find the suitable pane in the target tab
  -- Priority: 1) pane with focus_tab=true, 2) focused=true, 3) first pane
  local fallback_id = nil
  local focused_pane_id = nil

  for id, p_state in ipairs(all_panes) do
    if p_state and p_state._tab_id == target_tab_id then
      log.log("DEBUG", "vnix: Found target pane for tab navigation: " .. id)

      -- Store the first pane as fallback
      if not fallback_id then
        fallback_id = id
      end

      -- Prefer pane with focus_tab flag
      if p_state.focus_tab then
        return id, "t"
      end

      -- Also track if there's a focused pane
      if p_state.focused and not focused_pane_id then
        focused_pane_id = id
      end
    end
  end

  -- Return focused pane if available, otherwise fallback to first pane
  return focused_pane_id or fallback_id, "t"
end

function M.query_workspace(win, pane, delta, focus_setting)
  if not focus_setting then
    focus_setting = true
  end

  log.log("DEBUG", "vnix: query_workspace called with delta: " .. delta)
  local current_pane_state, _ = state.find_pane(win, pane)
  if not current_pane_state then
    log.log("WARN", "vnix: Could not find current pane in state for workspace navigation.")
    return nil
  end

  local all_panes = state.get()
  local workspaces = {}
  local ordered_workspace_names = {}

  -- Get all unique workspaces from the state, preserving order
  for _, p_state in ipairs(all_panes) do
    if p_state and not workspaces[p_state.workspace] then
      workspaces[p_state.workspace] = true
      table.insert(ordered_workspace_names, p_state.workspace)
    end
  end

  if #ordered_workspace_names <= 1 then
    log.log("DEBUG", "vnix: Not enough workspaces to navigate.")
    return nil
  end

  -- Find index of current workspace
  local current_workspace_index = -1
  for i, ws_name in ipairs(ordered_workspace_names) do
    if ws_name == current_pane_state.workspace then
      current_workspace_index = i
      break
    end
  end

  if current_workspace_index == -1 then
    log.log("DEBUG", "vnix: Could not find current workspace index.")
    return nil
  end

  -- Calculate target workspace index
  local target_workspace_index = (delta == "G" and #ordered_workspace_names)
    or (delta == "g" and 1)
    or (
      (current_workspace_index - 1 + delta + #ordered_workspace_names) % #ordered_workspace_names
      + 1
    )

  local target_workspace_name = ordered_workspace_names[target_workspace_index]
  log.log("DEBUG", "vnix: Target workspace name: " .. target_workspace_name)

  -- Find the suitable pane in the target workspace
  -- Priority: 1) pane with focus_workspace=true, 2) focused=true, 3) first pane
  local fallback_id = nil
  local focused_pane_id = nil

  for id, p_state in ipairs(all_panes) do
    if p_state and p_state.workspace == target_workspace_name then
      log.log("DEBUG", "vnix: Found target pane for workspace navigation: " .. id)

      -- Store the first pane as fallback
      if not fallback_id then
        fallback_id = id
      end

      -- Prefer pane with focus_workspace flag
      if p_state.focus_workspace then
        return id, "w"
      end

      -- Also track if there's a focused pane
      if p_state.focused and not focused_pane_id then
        focused_pane_id = id
      end
    end
  end

  -- Return focused pane if available, otherwise fallback to first pane
  return focused_pane_id or fallback_id, "w"
end

return M
