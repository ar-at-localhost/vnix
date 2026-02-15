local config = require("nvim.config")
local M = {}

---@param str string?
---@param repeatn integer?
---@param plus_half boolean?
function M.pad_str(str, repeatn, plus_half)
  local out = string.rep(config.pad, repeatn or 1) .. (str or "")
  if plus_half then
    out = config.pad_half .. out
  end
  return out
end

return M
