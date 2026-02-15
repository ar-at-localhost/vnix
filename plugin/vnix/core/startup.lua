local wezterm = require("wezterm")

local interval = 0.1 -- seconds
local M = {}

function M.gui_startup()
  local vnix = wezterm.GLOBAL.vnix
  wezterm.log_info("vnix: check gui-startup")

  if vnix and vnix.is_ready then
    wezterm.log_info("vnix: gui-startup ready")
    local log = require("vnix.utils.log")
    local state = require("vnix.core.state")

    local ok, err = pcall(function()
      log.log("info", "vnix: restoring session")
      vnix.state = state.load_from_file(vnix.workspaces_file)

      local restore_ok, restore_err = pcall(require("vnix.core.restore"), vnix)
      if not restore_ok then
        log.log("error", "vnix: Failed to restore session: " .. tostring(restore_err))
      else
        log.log("info", "vnix: successfully restored session")
      end
    end)

    if not ok then
      log.log("error", "vnix: Error during GUI startup: " .. tostring(err))
    end
  else
    wezterm.log_info("vnix: gui-startup not yet ready")
    -- Schedule next poll without blocking GUI
    wezterm.time.call_after(interval, M.gui_startup)
  end
end

return M
