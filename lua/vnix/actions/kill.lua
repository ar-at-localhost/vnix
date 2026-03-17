local wezterm = require("wezterm")
local state = require("vnix.state")
local events = require("vnix.events")
local act = wezterm.action
local vnix = wezterm.GLOBAL.vnix

---@class VnixKillMod
local M = {}

---Kill a pane
---@param win Window
---@param pane Pane
function M.kill(win, pane)
  local active_pane = vnix.runtime.active_pane
  if not active_pane then
    error("Nothing to be killed!")
  end

  win:perform_action(
    act.CloseCurrentPane({
      confirm = false,
    }),
    pane
  )

  local pane_state, tab_state, tab_idx, workspace_state, workspace_idx, parent_pane_state =
    state.find_pane_by_id(active_pane.id)

  if not pane_state or not tab_state then
    error("Failed to acquire active objects")
  end

  if parent_pane_state then
    if parent_pane_state.right and parent_pane_state.right.id == pane_state.id then
      parent_pane_state.right = pane_state.right or pane_state.bottom
    elseif parent_pane_state.bottom and parent_pane_state.bottom.id == pane_state.id then
      parent_pane_state.bottom = pane_state.right or pane_state.bottom
    end
  else
    ---@diagnostic disable-next-line: assign-type-mismatch
    tab_state.pane = pane_state.right or pane_state.bottom
  end

  if not tab_state.pane then
    M.kill_tab(win, pane, workspace_state, workspace_idx, tab_state, tab_idx)
  else
    vnix.runtime.active_pane = nil
    -- FIXME: It should've be 'constructive' event instead
    wezterm.emit("vnix:state-update", win, "init")
  end
end

---Kill a tab
---@param win Window
---@param pane Pane
---@param workspace VnixWorkspaceRuntime? Target workspace
---@param workspace_idx integer? Target workspace index (1-based)
---@param tab VnixTabRuntime? Target tab
---@param tab_idx integer? Target tab index (1-base)
function M.kill_tab(win, pane, workspace, workspace_idx, tab, tab_idx)
  local w, wi, t, ti = workspace, workspace_idx, tab, tab_idx

  if not w then
    local active_pane = vnix.runtime.active_pane
    if not active_pane then
      error("Unable to acquire active pane.")
    end

    _, t, ti, w, wi = state.find_pane_by_id(pane:pane_id())

    win:perform_action(
      wezterm.action.CloseCurrentTab({
        confirm = false,
      }),
      pane
    )

    pane = win:active_pane()
  end

  if not t or not ti or not w or not wi then
    error("Unable to acquire active objects.")
  end

  state.remove_tab(w, ti)
  vnix.runtime.focus[w.name] = nil
  vnix.runtime.focus[w.name .. "." .. t.id] = nil

  if #w.tabs <= 0 then
    M.kill_workspace(win, pane, w, wi)
  else
    local idx = ti - 1
    win:perform_action(wezterm.action.ActivateTab(idx), pane)
    wezterm.emit("vnix:state-update", win, "init")
  end
end

---Kill a workspace
---@param win Window
---@param pane Pane
---@param workspace VnixWorkspaceRuntime? Target workspace
---@param workspace_idx integer? Target workspace index (1-based)
function M.kill_workspace(win, pane, workspace, workspace_idx)
  local w, wi = workspace, workspace_idx

  if not w then
    local active_pane = vnix.runtime.active_pane
    if not active_pane then
      error("No active pane.")
    end

    _, _, _, w, wi = state.find_pane_by_id(pane:pane_id())
    if not w or not wi then
      error("Unable to acquire state objects.")
    end
  end

  -- keep __vnix__ workspace
  local MIN_WORKSPACES = 1

  if #vnix.runtime.workspaces <= MIN_WORKSPACES then
    local name = string.format("Untitled %d", win:active_tab():tab_id() + 1)
    ---@type VnixWorkspace
    local spec = {
      name = name,
      layout = {
        name = "blank",
        opts = {
          name = name,
        },
      },
      tabs = {},
    }

    wezterm.emit("vnix:create-workspace", win, pane, spec, function()
      win:perform_action(wezterm.action.SwitchToWorkspace({ name = spec.name }), pane)
      state.remove_workspace(MIN_WORKSPACES)
      wezterm.emit("vnix:state-update", win, "init")
    end)
  elseif wi then
    state.remove_workspace(wi)
    local new_workspace = vnix.runtime.workspaces[wi]
      or vnix.runtime.workspaces[wi + 1]
      or vnix.runtime.workspaces[wi - 1]

    if new_workspace then
      win:perform_action(
        wezterm.action.SwitchToWorkspace({
          name = new_workspace.name,
        }),
        pane
      )
    end

    vnix.runtime.focus[w.name] = nil
    for k, _ in pairs(vnix.runtime.focus) do
      if k:match("^%a+%.%d+$") then
        vnix.runtime.focus[k] = nil
      end
    end

    wezterm.emit("vnix:state-update", win, "init")
  end
end

events.make_event("vnix:kill", M.kill)
events.make_event("vnix:kill-tab", M.kill_tab)
events.make_event("vnix:kill-workspace", M.kill_workspace)
