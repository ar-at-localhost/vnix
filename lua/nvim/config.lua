local pad_half = "    "
---@type VNixNvimState
local vnix = {
  vnix_dir = "",
  flat_panes = {},
  workspaces = {},
  return_to = 0,
  last_known_req = 0,
  dev_workspaces = {},
  _ns = 0,
  pad_half = pad_half,
  pad = pad_half .. pad_half,
  --- FIXME: Make optional
  rpc = {},
}

return vnix
