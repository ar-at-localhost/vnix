local wezterm = require("wezterm")
local tbl = require("common.tbl")
local debug = require("vnix.keys.debug")
local nav = require("vnix.keys.nav")
local pane = require("vnix.keys.pane")
local common = require("vnix.keys.common")
local tab = require("vnix.keys.tab")
local workspace = require("vnix.keys.workspace")
local vnix = wezterm.GLOBAL.vnix

---@class VnixKeyGroup
---@field keys VNixKeybindings
---@field tables table<string, VnixKeyGroup>

---@type VnixKeyGroup
local Keys = {
  keys = tbl.deep_merge(common.keys, debug.keys, nav.keys, pane.keys, tab.keys, workspace.keys),
  tables = tbl.deep_merge(
    common.tables,
    debug.tables,
    nav.tables,
    pane.tables,
    tab.tables,
    workspace.tables
  ),
}

---@class VnixKeysMod
local M = {} ---@type VnixKeysMod

---Setup Vnix Vnix Keybindings
---@param config Config
---@param user_keys VNixKeybindings
function M.setup(config, user_keys)
  local infos = {}
  local merged = tbl.deep_merge(Keys.keys, user_keys)

  if not config.keys then
    config.keys = {}
  end

  for _, key in pairs(merged) do
    table.insert(config.keys, key)
    local info = tbl.deep_copy(key)
    info.action = nil
    table.insert(infos, info)
  end

  vnix.runtime.keybindings = infos
end

return M
