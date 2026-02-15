local pad_half = "    "
---@type VNixNvimState
local vnix = {
  vnix_dir = "",
  timesheet = "",
  state = {},
  return_to = 0,
  dev_workspaces = {},
  _ns = 0,
  pad_half = pad_half,
  pad = pad_half .. pad_half,
}

return vnix
