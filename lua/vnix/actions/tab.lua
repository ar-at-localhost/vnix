local wezterm = require("wezterm")
local events = require("vnix.events")
local state = require("vnix.state")
local vnix = wezterm.GLOBAL.vnix

---@diagnostic disable-next-line: unused-local
events.make_event("vnix:swap-tab", function(win, pane, offset)
  local p = vnix.runtime.active_pane or state:find_pane_by_id(pane:pane_id())

  if not p then
    error("Unable to acquire pane state!")
  end

  local workspace = state:find_workspace_by_name(p.workspace)
  if not workspace then
    error("Unable to acquire workspace state!")
  end

  local tabs = workspace.tabs
  if #tabs <= 1 then
    return
  end

  local found, idx = state:find_tab_by_id(workspace, p.tab_id)
  if not found or not idx then
    error("Unable to acquire tab state!")
  end

  local swap_idx = ((idx - 1 + offset) % #tabs) + 1

  if swap_idx == idx then
    return
  end

  tabs[idx], tabs[swap_idx] = tabs[swap_idx], tabs[idx]
  state:save_workspace(workspace)
end)

events.make_event("vnix:swap-tab-right", function(win, pane)
  wezterm.emit("vnix:swap-tab", win, pane, 1)
end)

events.make_event("vnix:swap-tab-left", function(win, pane)
  wezterm.emit("vnix:swap-tab", win, pane, -1)
end)
