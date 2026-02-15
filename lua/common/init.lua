---@module "vnix-common"
local M = {
  VNIX_NVIM_SOCK_PATH = "/tmp/vnix-nvim.sock",
  VNIX_USER_VAR_NAME = "vnixuservar",
}

local json = {
  encode =
    ---JSON Encode
    ---@param value unknown
    ---@return string
    function(value)
      local ok, wezterm = pcall(function()
        return require("wezterm")
      end)

      ---@cast wezterm Wezterm
      if ok and wezterm then
        return wezterm.json_encode(value)
      end

      return vim.json.encode(value)
    end,

  decode =
    ---JSON Decode
    ---@param value string
    ---@return unknown
    function(value)
      local ok, wezterm = pcall(function()
        return require("wezterm")
      end)

      ---@cast wezterm Wezterm
      if ok and wezterm then
        return wezterm.json_parse(value)
      end

      return vim.json.decode(value)
    end,
}

---Create a response out of request
---@param req UIMessageReqBase
---@param data unknown
---@return UIMessageRespBase
function M.create_resp(req, data)
  ---@type UIMessageRespBase
  local resp = {
    id = req.id,
    type = req.type,
    timestamp = req.timestamp, -- TODO: Use new timestamp
    return_to = req.return_to,
    data = data,
  }

  return resp
end

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
    local json_str = json.encode(tbl)
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
    return json.decode(content)
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

function M.obj_to_tbl(obj)
  local numeric = {}

  for k, v in pairs(obj) do
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

---@cast M VNixCommon
return M
