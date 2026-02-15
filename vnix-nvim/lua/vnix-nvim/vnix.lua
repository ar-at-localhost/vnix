---@type VNixNvimState
local vnix = {
  vnix_dir = "",
  timesheet = "",
  activity = {
    file = "",
    cp_id = 0,
    tt = false,
    tts = 0,
    total_time_today = 0,
    total_break_today = 0,
    total_non_break_today = 0,
  },
  state = {},
  return_to = 0,
  dev_workspaces = {},
}

return vnix
