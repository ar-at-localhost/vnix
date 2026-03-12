local pad_half = "    "

-- selene: allow
_G.__vnix = _G.__vnix or {
  watchers = {},
}

---@type VNixNvimState
local vnix = {
  G = _G.__vnix,
  vnix_dir = "",
  src_dir = "",
  flat_panes = {},
  active_pane = nil,
  workspaces = {},
  return_to = 0,
  last_known_req = 0,
  dev_workspaces = {},
  _ns = 0,
  pad_half = pad_half,
  pad = pad_half .. pad_half,
  --- FIXME: Make optional
  rpc = {},
  rpc_active = nil,
  pickers = {},
}

if vnix.src_dir and vnix.src_dir ~= "" then
  vnix.src_dir = vnix.src_dir .. "/lua"
end

return vnix
