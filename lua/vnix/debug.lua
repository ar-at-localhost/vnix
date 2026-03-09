local wezterm = require("wezterm")
local M = {}

---Check if the path represents an existing directory
---@param path string
local function is_dir(path)
  return os.execute("[ -d \"" .. path .. "\" ]") == 0
end

---Retrieve the extname of the file
---@param path string
local function get_extension(path)
  return path:match("%.(%w+)$")
end

---@param dir string
function M._add_to_watch(dir)
  for _, v in ipairs(wezterm.read_dir(dir)) do
    if is_dir(v) then
      M._add_to_watch(v)
    elseif get_extension(v) == "lua" then
      print("Added to watch: " .. v)
      wezterm.add_to_config_reload_watch_list(v)
    end
  end
end

function M.setup_dev_watch()
  local plugin_dir = os.getenv("VNIX_PLUGIN_DIR")
  if not plugin_dir then
    return
  end
  local dirs = { "common", "nvim" }
  for _, dir in ipairs(dirs) do
    M._add_to_watch(string.format("%s/lua/%s", plugin_dir, dir))
  end
end

return M
