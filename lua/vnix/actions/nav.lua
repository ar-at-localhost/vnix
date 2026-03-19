local wezterm = require("wezterm")
local common = require("common")
local state = require("vnix.state")
local activity = require("vnix.activity")
local mux = require("vnix.mux")
local vnix = wezterm.GLOBAL.vnix

-- Helper to perform a WezTerm action and refresh vnix state
local function navigate(win, pane, action)
  win:perform_action(action, pane)
  wezterm.emit("vnix:state-update", win, "effective")
end

---Workspace navigation
---@param win Window
---@param pane Pane
---@param offset? integer
local function switch_workspace(win, pane, offset)
  local active_pane = vnix.runtime.active_pane

  if not active_pane then
    return
  end

  local current_workspace, idx = state.find_workspace_by_name(active_pane.workspace)
  if not current_workspace or not idx then
    return
  end

  local target = nil
  while true do
    local total_workspaces = #vnix.runtime.workspaces
    idx = ((idx - 1 + offset) % total_workspaces) + 1
    local candidate = vnix.runtime.workspaces[idx]

    if not candidate or candidate.id == current_workspace.id then
      -- wrapped around, no valid workspace found
      break
    end

    if not candidate.lazy or candidate.lazy_loaded then
      target = candidate
      break
    end
  end

  if not target then
    return
  end

  win:perform_action(wezterm.action.SwitchToWorkspace({ name = target.name }), pane)

  local focused_pane = activity.lookup_focused_pane(target.name)
  if focused_pane then
    local _, tab_idx = state.find_tab_by_id(target, focused_pane.tab_id)
    if tab_idx then
      win:perform_action(wezterm.action.ActivateTab(tab_idx), pane)
      win:perform_action(wezterm.action.ActivatePaneByIndex(focused_pane.idx), pane)
    end
  end

  wezterm.emit("vnix:state-update", win, "effective")
end

---Tab navigation (relative to current tab)
---@param win Window
---@param pane Pane
---@param offset_or_idx? integer Provide +1/-1 or exact index (except 1 - which will be taken as `offset`)
local function switch_tab(win, pane, offset_or_idx)
  local index = 0
  local active_pane = vnix.runtime.active_pane

  if offset_or_idx ~= 1 and offset_or_idx ~= -1 then
    index = offset_or_idx
  elseif active_pane then
    local workspace = state.find_workspace_by_name(active_pane.workspace)
    if workspace then
      local active_tab, tab_idx = state.find_tab_by_id(workspace, active_pane.tab_id)

      if active_tab and tab_idx then
        ---@type VnixTabRuntime?
        local target_tab
        while true do
          tab_idx = (((tab_idx - 1) + offset_or_idx) % #workspace.tabs) + 1
          local candidate = workspace.tabs[tab_idx]
          if not candidate or candidate.id == active_tab.id then
            -- wrapped around, no valid tab found
            break
          end
          if not candidate.lazy or candidate.lazy_loaded then
            target_tab = candidate
            break
          end
          -- lazy and not loaded: skip, continue iterating
        end

        if target_tab then
          local _, i = mux.find_tab(target_tab.id)
          if i then
            index = i
          end
        end
      end
    end
  end

  win:perform_action(wezterm.action.ActivateTab(index), pane)
  wezterm.emit("vnix:state-update", win, "effective")
end

-- Pane navigation
wezterm.on("vnix:nav-pane-left", function(win, pane)
  navigate(win, pane, wezterm.action({ ActivatePaneDirection = "Left" }))
end)

wezterm.on("vnix:nav-pane-right", function(win, pane)
  navigate(win, pane, wezterm.action({ ActivatePaneDirection = "Right" }))
end)

wezterm.on("vnix:nav-pane-up", function(win, pane)
  navigate(win, pane, wezterm.action({ ActivatePaneDirection = "Up" }))
end)

wezterm.on("vnix:nav-pane-down", function(win, pane)
  navigate(win, pane, wezterm.action({ ActivatePaneDirection = "Down" }))
end)

-- Tab navigation
wezterm.on("vnix:nav-tab-next", function(win, pane)
  switch_tab(win, pane, 1)
end)

wezterm.on("vnix:nav-tab-prev", function(win, pane)
  switch_tab(win, pane, -1)
end)

wezterm.on("vnix:nav-tab-first", function(win, pane)
  switch_tab(win, pane, 0)
end)

wezterm.on("vnix:nav-tab-last", function(win, pane)
  switch_tab(win, pane, #win:tabs())
end)

-- Workspace navigation
wezterm.on("vnix:nav-workspace-next", function(win, pane)
  switch_workspace(win, pane, 1)
end)

wezterm.on("vnix:nav-workspace-prev", function(win, pane)
  switch_workspace(win, pane, -1)
end)

wezterm.on("vnix:nav-workspace-first", function(win, pane)
  -- TODO: Restore
  -- switch_workspace(win, pane, 0)
end)

wezterm.on("vnix:nav-workspace-last", function(win, pane)
  -- TODO: Restore
  -- switch_workspace(win, pane, #vnix.runtime.workspaces)
end)
