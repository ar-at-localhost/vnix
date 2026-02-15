local wezterm = require("wezterm")
local query = require("vnix.state.state-query")
local log = require("vnix.utils.log")

local function navigate(win, pane, direction, query_func, ...)
  local target_id, context = query_func(win, pane, ...)

  if target_id then
    wezterm.emit(
      "vnix:switch-to",
      win,
      pane,
      target_id,
      context,
      context == "p" and direction or nil
    )
  else
    log.log("INFO", "vnix: No target found for navigation: " .. direction)
  end
end

wezterm.on("vnix:nav-pane-left", function(win, pane)
  navigate(win, pane, "Left", query.query_pane_in_direction, "Left", true)
end)

wezterm.on("vnix:nav-pane-right", function(win, pane)
  navigate(win, pane, "Right", query.query_pane_in_direction, "Right", true)
end)

wezterm.on("vnix:nav-pane-up", function(win, pane)
  navigate(win, pane, "Up", query.query_pane_in_direction, "Up", true)
end)

wezterm.on("vnix:nav-pane-down", function(win, pane)
  navigate(win, pane, "Down", query.query_pane_in_direction, "Down", true)
end)

wezterm.on("vnix:nav-tab-next", function(win, pane)
  navigate(win, pane, "Tab Next", query.query_tab, 1, true)
end)

wezterm.on("vnix:nav-tab-prev", function(win, pane)
  navigate(win, pane, "Tab Prev", query.query_tab, -1, true)
end)

wezterm.on("vnix:nav-tab-first", function(win, pane)
  navigate(win, pane, "Tab First", query.query_tab, 0, true)
end)

wezterm.on("vnix:nav-tab-last", function(win, pane)
  navigate(win, pane, "Tab Last", query.query_tab, "$", true)
end)

wezterm.on("vnix:nav-workspace-next", function(win, pane)
  navigate(win, pane, "Workspace Next", query.query_workspace, 1, true)
end)

wezterm.on("vnix:nav-workspace-prev", function(win, pane)
  navigate(win, pane, "Workspace Prev", query.query_workspace, -1, true)
end)

wezterm.on("vnix:nav-workspace-first", function(win, pane)
  navigate(win, pane, "Workspace First", query.query_workspace, "g", true)
end)

wezterm.on("vnix:nav-workspace-last", function(win, pane)
  navigate(win, pane, "Workspace Last", query.query_workspace, "G", true)
end)
