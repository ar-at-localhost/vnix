local wezterm = require("wezterm")
local rpc = require("vnix.rpc")
local vnix = wezterm.GLOBAL.vnix
local M = {}

---Retrieve the extname of the file
---@param path string
local function get_extension(path)
  return path:match("%.(%w+)$")
end

---@param dir string
function M._add_to_watch(dir)
  return pcall(function()
    for _, v in ipairs(wezterm.read_dir(dir)) do
      local ok = M._add_to_watch(v)
      if not ok then
        if get_extension(v) == "lua" then
          wezterm.add_to_config_reload_watch_list(v)
          print("Added to watch: " .. v)
        end
      end
    end
  end)
end

function M.handle_reload()
  if vnix.debug and vnix.is_ready then
    print("Dispatching reload")
    rpc.dispatch_cmd("reload")
  end
end

return M
