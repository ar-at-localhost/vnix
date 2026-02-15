local wezterm = require("wezterm")
local vnix = wezterm.GLOBAL.vnix
local M = {}

-- Capture a log.
--
-- @param type 'INFO'|'WARN'|'ERROR': The severity level of the log message.
-- @param text string: The log message.
function M.log(type, text)
  vnix.log_count = vnix.log_count + 1
  local key = tostring(vnix.log_count)
  local timestamp = os.date("!%Y-%m-%dT%TZ", os.time())
  vnix.logs[key] = { type = string.lower(type), text = text, timestamp = timestamp }
end

local function flush_logs()
  -- Always truncate on startup
  if vnix.log_count == 0 then
    local ok, fh = pcall(function()
      return io.open(vnix.log_file, "w")
    end)
    if ok and fh then
      fh:close()
    else
      wezterm.log_error("vnix: Failed to truncate log file: " .. tostring(fh))
    end
  end

  local fh, err = io.open(vnix.log_file, "a")
  if not fh then
    wezterm.log_error("vnix: cannot open log file for appending: " .. tostring(err))
    return
  end

  for i = vnix.flushed_logs_count + 1, vnix.log_count do
    local entry = vnix.logs[tostring(i)]
    if not entry then
      wezterm.log_info("vnix: nothing more to log:", i)
      break
    end

    local log_msg = string.format("[%s | %s]: %s\n", entry.type, entry.timestamp, entry.text)
    if vnix.debug then
      wezterm.log_info(log_msg)
    end

    local ok, werr = pcall(function()
      fh:write(log_msg)
    end)

    if not ok then
      wezterm.log_error("vnix: failed writing to log file: " .. tostring(werr))
      break
    end

    vnix.logs[tostring(i)] = nil
    vnix.flushed_logs_count = i
  end

  print("vnix: flushed logs:", vnix.flushed_logs_count)
  fh:close()
end

local function safe_log_to_file()
  local ok, err = pcall(flush_logs)
  if not ok then
    wezterm.log_error("vnix: log flush failed: " .. tostring(err))
  end

  -- Only schedule next flush if not in test environment
  -- Test environment detection: check if wezterm.GLOBAL.vnix exists and has test markers
  local is_test_env = vnix and vnix.log_file and string.match(vnix.log_file, "_test")
  if not is_test_env then
    wezterm.time.call_after(1.0, safe_log_to_file)
  end
end

-- Start flush cycle only if not in test environment
if not (vnix and vnix.log_file and string.match(vnix.log_file, "_test")) then
  safe_log_to_file()
end

return { log = M.log }
