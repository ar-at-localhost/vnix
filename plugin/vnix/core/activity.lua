local fs = require("vnix.utils.fs")
local M = {}

---Loads activity file from given path
---@param path string
---@return table
function M.load_from_file(path)
  return fs.safe_read_json(path, {
    cp_id = 0,
    tt = true,
    tts = nil,
    total_time_today = 0,
    total_non_break_today = 0,
    total_break_today = 0,
    file = path,
  })
end

return M
