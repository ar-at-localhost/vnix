local wezterm = require("wezterm")
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
---@param offset number
local function switch_workspace(win, pane, offset)
  local fallback = function()
    win:perform_action(wezterm.action.SwitchWorkspaceRelative(offset), pane)
    wezterm.emit("vnix:state-update", win, "effective")
  end

  local current = win:active_workspace()
  local current_workspace, idx = state.find_workspace_by_name(current)

  if not current_workspace or not idx then
    fallback()
  end

  local total_workspaces = #vnix.runtime.workspaces
  local target_idx = idx + offset
  if target_idx < 1 then
    target_idx = total_workspaces
  elseif target_idx > total_workspaces then
    target_idx = 1
  end

  local target = vnix.runtime.workspaces[target_idx]
  if not target then
    fallback()
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
      local _, tab_idx = state.find_tab_by_id(workspace, active_pane.tab_id)
      local idx = (((tab_idx - 1) + offset_or_idx) % #workspace.tabs) + 1
      local target_tab = workspace.tabs[idx]

      if target_tab then
        local _, i = mux.find_tab(target_tab.id)
        if i then
          index = i
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
  navigate(win, pane, wezterm.action({ SwitchWorkspaceRelative = 0 }))
end)

wezterm.on("vnix:nav-workspace-last", function(win, pane)
  navigate(win, pane, wezterm.action({ SwitchWorkspaceRelative = -1 }))
end)
