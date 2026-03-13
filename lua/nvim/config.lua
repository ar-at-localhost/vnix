local pad_half = "    "

-- selene: allow
_G.__vnix = _G.__vnix or {}

---@type VNixNvimState
local vnix = {
  watchers = {},
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

local src = os.getenv("VNIX_PLUGIN_DIR")
if src and src ~= "" then
  _G.__vnix = vnix
  return _G.__vnix
end

return vnix
