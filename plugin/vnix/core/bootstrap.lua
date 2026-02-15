local wezterm = require("wezterm")
local activity = require("vnix.core.activity")
local M = {}

---@param opts VNixConfig
function M.setup(opts)
  local G = wezterm.GLOBAL

  if not G.vnix then
    local user_home = os.getenv("HOME") or "/"

    local vnix_home = (opts.vnix_dir and (user_home .. "/" .. opts.vnix_dir))
      or (user_home .. "/.vnix")

    os.execute("mkdir -p " .. vnix_home)
    local workspaces_file = opts.workspaces_file or (vnix_home .. "/panes.json")
    local activity_file = vnix_home .. "/activity.json"

    G.vnix = {
      vnix_dir = vnix_home,
      log_count = 0,
      flushed_logs_count = 0,
      logs = {},
      log_file = vnix_home .. "/logs.log",
      shell = os.getenv("SHELL") or "/bin/bash",
      user_home = user_home,
      home = vnix_home,
      workspaces_file = workspaces_file,
      state_file = vnix_home .. "/state.json",
      current_pane_index = nil,
      original_workspace = nil,
      activity_file = activity_file,
      activity = activity.load_from_file(activity_file),
      timesheet = nil,
      timesheet_file = vnix_home
        .. "/timesheet-"
        .. tostring(os.date("%x")):gsub("/", "-")
        .. ".json",

      ui_next_req = 1,
      is_ready = true,
      debug = opts.debug or false,
    }

    -- Load logs module
    require("vnix.utils.log")

    -- Load all event handlers so they are registered with WezTerm
    require("vnix.core.time")
    require("vnix.utils.misc")
  end
end

return M
