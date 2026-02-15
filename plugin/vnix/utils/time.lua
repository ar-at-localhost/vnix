local M = {}

function M.format_date(time)
  return os.date("%Y-%m-%d", time)
end

function M.format_time_diff(diff)
  if not diff then
    diff = 0
  end

  local hours = math.floor(diff / 3600)
  local minutes = math.floor((diff % 3600) / 60)

  return string.format("%02d:%02d", hours, minutes)
end

--- ISO 8601 timestamp (UTC)
--- @param time? number
--- @return string
function M.iso_timestamp(time)
  return tostring(os.date("!%Y-%m-%dT%H:%M:%SZ", time))
end

return M
