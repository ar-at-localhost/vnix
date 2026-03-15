local wezterm = require("wezterm")
local activity = require("vnix.activity")
local str = require("common.str")
local M = {}

---@param opts VNixConfig
function M.setup(opts)
  local G = wezterm.GLOBAL
  local plugin_dir = os.getenv("VNIX_PLUGIN_DIR")
  local is_dev = opts.dev or (plugin_dir and plugin_dir ~= "")

  if not G.vnix then
    local user_home = os.getenv("HOME") or "/"

    local vnix_home = (
      opts.vnix_dir and ((is_dev and opts.vnix_dir) or (user_home .. "/" .. opts.vnix_dir))
    ) or (user_home .. "/.vnix")

    os.execute("mkdir -p " .. vnix_home)
    local activity_file = vnix_home .. "/activity.json"

    local function get_primary_path()
      if str.is_absolute_path(opts.specs_file_primary) then
        return opts.specs_file_primary
      end

      local name = opts.specs_file_primary
      if not name or name == "" then
        name = "vnix.json"
      end

      return string.format("%s/%s", vnix_home, name)
    end

    G.vnix = {
      sock_path = string.format("/tmp/vnix%s.sock", is_dev and "-dev" or ""),
      vnix_dir = vnix_home,
      shell = os.getenv("SHELL") or "/bin/bash",
      user_home = user_home,
      home = vnix_home,
      specs_file_secondary = string.format(
        "%s/%s",
        vnix_home,
        opts.specs_file_secondary or "specs.json"
      ),
      specs_file_primary = get_primary_path(),
      specs_file_primary_out = string.format("%s/%s", vnix_home, "vnix.json"),
      original_workspace = nil,
      activity_file = activity_file,
      runtime = activity.load_from_file(activity_file),
      ui_next_req = 1,
      is_ready = true,
      debug = opts.debug or false,
      status = {},
    }
  end
end

return M
