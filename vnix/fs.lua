local wezterm = require("wezterm")

local M = {}

--- Attempts to create a new file at the given path.
---@param path string The file path to create.
---@return boolean success True if the file was created successfully, false otherwise.
function M.attempt_create_file(path)
  local success, _ = pcall(function()
    local file = io.open(path, "w")
    if not file then
      error("Failed to create file: " .. path)
    end
    file:close()
  end)
  return success
end

--- Write plain string to file (overwrite).
---@param path string
---@param data string
---@return boolean success
---@return string|nil err
function M.write_file(path, data)
  local ok, err = pcall(function()
    local file = assert(io.open(path, "w"))
    file:write(data)
    file:close()
  end)
  return ok, ok and nil or err
end

--- Read plain string from file.
---@param path string
---@return string|nil content
---@return string|nil err
function M.read_file(path)
  local ok, result = pcall(function()
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end)
  if ok then
    return result, nil
  else
    return nil, result
  end
end

--- Write Lua table as JSON to file.
---@param path string
---@param tbl table
---@return boolean success
---@return string|nil err
function M.write_json(path, tbl)
  local ok, err = pcall(function()
    local json_str = wezterm.json_encode(tbl)
    local file = assert(io.open(path, "w"))
    file:write(json_str)
    file:close()
  end)
  return ok, ok and nil or err
end

--- Read Lua table from JSON file.
---@param path string
---@return table|nil data
---@return string|nil err
function M.read_json(path)
  local content, read_err = M.read_file(path)
  if not content then
    return nil, read_err
  end

  local ok, result = pcall(function()
    return wezterm.json_parse(content)
  end)

  if ok then
    return result, nil
  else
    return nil, result
  end
end

function M.safe_read_json(path, default_tbl)
  local data = M.read_json(path)
  if data and type(data) == "table" then
    return data
  end
  -- file missing or invalid → overwrite with default
  M.write_json(path, default_tbl)
  return default_tbl
end

return M
