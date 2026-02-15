local wezterm = require("wezterm")
local log = require("vnix.utils.log")

local M = {}

-- FIXME: Cleanup
-- Create named pipes for communication
function M.create_pipes(input_path, output_path)
  log.log("INFO", "vnix: creating pipes - input: " .. input_path .. ", output: " .. output_path)

  -- Remove existing pipes if they exist
  local remove_input_ok, remove_input_err = pcall(function()
    os.remove(input_path)
  end)
  if not remove_input_ok then
    log.log("WARN", "vnix: failed to remove existing input pipe: " .. tostring(remove_input_err))
  end

  local remove_output_ok, remove_output_err = pcall(function()
    os.remove(output_path)
  end)
  if not remove_output_ok then
    log.log("WARN", "vnix: failed to remove existing output pipe: " .. tostring(remove_output_err))
  end

  -- Create input pipe
  local input_ok, input_err = pcall(function()
    local handle = io.popen("mkfifo " .. input_path .. " 2>&1", "r")
    if not handle then
      error("Failed to create input pipe: " .. input_path)
    end

    local output = handle:read("*a")
    local _, _, code = handle:close()
    if code ~= 0 then
      log.log("ERROR", "vnix: mkfifo failed for input pipe: " .. output)
      error("Failed to create input pipe: " .. output)
    end
  end)

  if not input_ok then
    log.log("ERROR", "vnix: failed to create input pipe: " .. tostring(input_err))
    return false
  end

  -- Create output pipe
  local output_ok, output_err = pcall(function()
    local handle = io.popen("mkfifo " .. output_path .. " 2>&1", "r")
    if not handle then
      error("Failed to create output pipe: " .. output_path)
    end

    local output = handle:read("*a")
    local _, _, code = handle:close()
    if code ~= 0 then
      log.log("ERROR", "vnix: mkfifo failed for output pipe: " .. output)
      error("Failed to create output pipe: " .. output)
    end
  end)

  if not output_ok then
    log.log("ERROR", "vnix: failed to create output pipe: " .. tostring(output_err))
    -- Clean up input pipe on failure
    os.remove(input_path)
    return false
  end

  log.log("INFO", "vnix: pipes created successfully")
  return true
end

-- Write message to input pipe
function M.write_to_pipe(pipe_path, message)
  if not pipe_path then
    log.log("ERROR", "vnix: no pipe path provided for writing")
    return false
  end

  local write_ok, write_err = pcall(function()
    local file = io.open(pipe_path, "w")
    if not file then
      error("Cannot open pipe for writing: " .. pipe_path)
    end
    file:write(message .. "\n")
    file:flush()
    file:close()
  end)

  if not write_ok then
    log.log("ERROR", "vnix: failed to write to pipe: " .. tostring(write_err))
    return false
  end

  log.log("DEBUG", "vnix: message written to pipe: " .. message)
  return true
end

function M.async_read_from_pipe(pipe_path, callback, poll_interval)
  poll_interval = poll_interval or 0.2

  local function read_once()
    -- Read with a larger timeout and explicit buffer size
    local handle =
      io.popen("timeout 1 dd if=\"" .. pipe_path .. "\" bs=65536 2>/dev/null || true", "r")
    if handle then
      local data = handle:read("*a")
      handle:close()

      if data and data ~= "" then
        data = data:gsub("\n$", "")
        callback(data)
      end
    end

    wezterm.time.call_after(poll_interval, read_once)
  end

  read_once()
end

-- Clean up pipes
function M.cleanup_pipes(input_path, output_path)
  log.log("INFO", "vnix: cleaning up pipes")

  if input_path then
    os.remove(input_path)
  end

  if output_path then
    os.remove(output_path)
  end
end

-- Check if pipes exist and are accessible
function M.check_pipes(input_path, output_path)
  if not input_path or not output_path then
    return false
  end

  local input_exists = io.open(input_path, "r") ~= nil
  local output_exists = io.open(output_path, "w") ~= nil

  if input_exists then
    io.close(io.open(input_path, "r"))
  end
  if output_exists then
    io.close(io.open(output_path, "w"))
  end

  return input_exists and output_exists
end

return M
