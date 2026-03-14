local pad_half = "    "

local function init()
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
    debug = {
      handles = {},
    },
    highlights = {},
    org = {
      keywords = { "TODO", "PROG", "|", "DONE", "CLOSED" },
      sorts = { "deadline", "priority" },
    },
  }

  return vnix
end

local src = os.getenv("VNIX_PLUGIN_DIR")
if src and src ~= "" then
  _G.__vnix = _G.__vnix or init()
  _G.__vnix.dev = true
  return _G.__vnix
end

return init()
