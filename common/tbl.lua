---@class TableUtils
---@field deep_copy fun(a: table, _seen?: table): table deep copy tables
---@field deep_equal fun(a: table, b: table, _seen: table?): boolean Check if 2 tables are deeply equal
---@field merge_all fun(...: table): table Merge multiple tables
---@field slice fun(arg: table, first: number, last?: number): table Slice a table
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

function M.merge_all(...)
  local result = {}
  for _, tbl in ipairs({ ... }) do
    if type(tbl) == "table" then
      for k, v in pairs(tbl) do
        result[k] = v
      end
    end
  end
  return result
end

function M.deep_copy(orig, seen)
  if type(orig) ~= "table" then
    return orig
  end

  seen = seen or {}
  if seen[orig] then
    return seen[orig]
  end

  local copy = {}
  seen[orig] = copy

  for k, v in pairs(orig) do
    copy[M.deep_copy(k, seen)] = M.deep_copy(v, seen)
  end

  return setmetatable(copy, getmetatable(orig))
end

function M.slice(arg, first, last)
  local sliced = {}
  first = first or 1
  last = last or #arg
  for i = first, last do
    sliced[#sliced + 1] = arg[i]
  end
  return sliced
end

function M.keys_to_num(t)
  -- Validate input parameter
  if not t then
    error("Invalid table provided to keys_to_num")
  end

  local numeric = {}
  for k, v in pairs(t) do
    if k ~= nil then -- Ensure key is not nil
      local num_key = tonumber(k)
      if num_key then
        numeric[num_key] = v
      else
        numeric[k] = v
      end
    end
  end

  return numeric
end

return M
