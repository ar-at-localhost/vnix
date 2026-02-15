local wezterm = require("wezterm")
local fs = require("vnix.fs")
local vnix = wezterm.GLOBAL.vnix

---@class VnixActivityMod
---@field load_from_file fun(path: string): VnixActivity Load activity from file
---@field lookup_focused_pane fun(workspace: string, tab?: number): VnixPaneState? Lookup pane from activity
---@field set_focused_pane fun(pane: VnixPaneState) Save pane to activity
local M = {}

---Loads activity file from given path
---@param path string
---@return VnixActivity
function M.load_from_file(path)
  ---@type VnixActivity
  local res = fs.safe_read_json(path, {})
  res.active_pane = res.active_pane or nil
  res.focus = res.focus or {
    tab = {},
    workspace = {},
  }

  return res
end

function M.lookup_focused_pane(workspace, tab_id)
  local path = workspace
  if tab_id then
    path = path .. "." .. tostring(tab_id)
  end

  return vnix.activity.focus[path]
end

function M.set_focused_pane(pane)
  local activity = vnix.activity
  activity.active_pane = pane
  activity.focus[pane.workspace] = pane
  activity.focus[pane.workspace .. "." .. pane.tab_id] = pane
end

return M
