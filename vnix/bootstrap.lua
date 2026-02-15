local wezterm = require("wezterm")
local activity = require("vnix.activity")
local M = {}

---@param opts VNixConfig
function M.setup(opts)
  local G = wezterm.GLOBAL
  local is_dev = opts.dev

  if not G.vnix then
    local user_home = os.getenv("HOME") or "/"

    local vnix_home = (
      opts.vnix_dir and ((is_dev and opts.vnix_dir) or (user_home .. "/" .. opts.vnix_dir))
    ) or (user_home .. "/.vnix")

    os.execute("mkdir -p " .. vnix_home)
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
      config_file = vnix_home .. "/config.json",
      workspaces = {},
      state_flat = {},
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
  end
end

return M
