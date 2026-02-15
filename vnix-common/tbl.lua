---@class TableUtils
---@field deep_equal fun(a: table, b: table, seen: table): boolean
local M = {} ---@type TableUtils

function M.deep_equal(a, b, seen)
  if a == b then
    return true
  end
  if type(a) ~= type(b) or type(a) ~= "table" then
    return false
  end

  seen = seen or {}
  local key = tostring(a) .. "|" .. tostring(b)
  if seen[key] then
    return true
  end
  seen[key] = true

  for k, v in pairs(a) do
    if not M.deep_equal(v, b[k], seen) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end

  return true
end

return M
