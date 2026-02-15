local TableUtils = {}

--- @param orig table
--- Deep Copy an object
function TableUtils.deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[TableUtils.deepcopy(orig_key)] = TableUtils.deepcopy(orig_value)
    end
    setmetatable(copy, TableUtils.deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

--- Merge 2 tables
--- @param base table
--- @param overrides table
function TableUtils.merge(base, overrides)
  local result = {}

  -- copy base
  for k, v in pairs(base) do
    result[k] = v
  end

  -- apply overrides
  for k, v in pairs(overrides) do
    result[k] = v
  end

  return result
end

--- Merge multiple tables
--- Later tables override earlier ones
--- @param ... table Any number of tables to merge
--- @return table The merged table
function TableUtils.merge_all(...)
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

return TableUtils
