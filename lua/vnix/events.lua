local wezterm = require("wezterm")

---@class VnixEventsMod
local M = {}

---Register a wezterm event (`wezterm.on`) with safe pcall
---@param name string event name
---@param callback fun(...)
function M.make_event(name, callback)
  wezterm.on(name, function(...)
    local args = { ... }
    local ok, err = pcall(callback, table.unpack(args))

    if not ok then
      wezterm.log_error(string.format("Error processing %s:", name), err)
    end
  end)
end

return M
