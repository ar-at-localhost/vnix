local M = {}

local MAGIC_CHARS = "^$()%.[]*+-?"

local function glob_to_pattern(pattern)
  local result = "^"
  local i = 1
  local len = #pattern

  while i <= len do
    local c = pattern:sub(i, i)
    if c == "*" then
      if i < len and pattern:sub(i + 1, i + 1) == "*" then
        result = result .. ".*"
        i = i + 2
      else
        result = result .. "[^/]*"
        i = i + 1
      end
    elseif c == "?" then
      result = result .. "[^/]"
      i = i + 1
    elseif MAGIC_CHARS:find(c, 1, true) then
      result = result .. "%" .. c
      i = i + 1
    else
      result = result .. c
      i = i + 1
    end
  end

  return result .. "$"
end

local function should_ignore(filepath, ignore_patterns)
  for _, pattern in ipairs(ignore_patterns) do
    if filepath:match(glob_to_pattern(pattern)) then
      return true
    end
  end
  return false
end

function M.watch_directory(dirpath, opts, callback)
  if type(opts) == "function" then
    callback = opts
    opts = {}
  end

  opts = opts or {}
  local recursive = opts.recursive or false
  local debounce_ms = opts.debounce_ms or 100
  local ignore_patterns = opts.ignore_patterns or {}

  local debounce_timer
  local pending_events = {}
  local wrapper

  local function flush_events()
    if debounce_timer then
      debounce_timer:stop()
      debounce_timer:close()
      debounce_timer = nil
      wrapper._timer = nil
    end

    for filepath, events in pairs(pending_events) do
      if not should_ignore(filepath, ignore_patterns) then
        callback(filepath, events)
      end
    end

    pending_events = {}
  end

  local handle = vim.uv.new_fs_event()
  if not handle then
    vim.notify("Failed to create fs event handle", vim.log.levels.ERROR)
    return nil
  end

  wrapper = {
    _handle = handle,
    _timer = nil,

    stop = function(self)
      if self._handle then
        self._handle:stop()
        self._handle:close()
        self._handle = nil
      end

      if self._timer then
        self._timer:stop()
        self._timer:close()
        self._timer = nil
      end
    end,
  }

  local wrapped_callback = vim.schedule_wrap(function(err, filename, events)
    if err then
      vim.notify("Watch error: " .. err, vim.log.levels.ERROR)
      return
    end

    if not filename then
      return
    end

    local filepath = vim.fs.joinpath(dirpath, filename)

    if not pending_events[filepath] then
      pending_events[filepath] = { change = false, rename = false }
    end

    if events.change then
      pending_events[filepath].change = true
    end
    if events.rename then
      pending_events[filepath].rename = true
    end

    if debounce_timer then
      debounce_timer:stop()
    else
      debounce_timer = vim.uv.new_timer()
      wrapper._timer = debounce_timer
    end

    if debounce_timer then
      debounce_timer:start(debounce_ms, 0, vim.schedule_wrap(flush_events))
    end
  end)

  local ok, err = pcall(handle.start, handle, dirpath, { recursive = recursive }, wrapped_callback)
  if not ok then
    handle:close()
    vim.notify("Failed to start fs watcher: " .. tostring(err), vim.log.levels.ERROR)
    return nil
  end

  return wrapper
end

function M.stop_all(watchers)
  if not watchers then
    return
  end
  for _, watcher in ipairs(watchers) do
    watcher:stop()
  end
end

local function setup()
  local common = require("vnix-common")
  local vnix = require("vnix-nvim.vnix")

  local active_watchers = {}

  local watcher = M.watch_directory(
    vnix.vnix_dir,
    { recursive = true, ignore_patterns = { "timesheet-*.csv" } },
    function(filepath)
      local name = vim.fs.basename(filepath)
      if name == "activity.json" then
        local data = common.read_json(vnix.vnix_dir .. "/" .. name)
        if data then
          vnix.activity = data
        else
          vim.notify("Failed to read activity.json", vim.log.levels.WARN)
        end
      elseif name == "state.json" then
        local data = common.read_json(vnix.vnix_dir .. "/" .. name)
        if data then
          require("vnix-nvim.state").process(data)
        else
          vim.notify("Failed to read state.json", vim.log.levels.WARN)
        end
      elseif name == "req.json" then
        local data = common.read_json(vnix.vnix_dir .. "/" .. name)
        if data then
          require("vnix-nvim.req").handle_request(data)
        else
          vim.notify("Failed to read req.json", vim.log.levels.WARN)
        end
      end
    end
  )

  if watcher then
    table.insert(active_watchers, watcher)
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.stop_all(active_watchers)
    end,
  })
end

return setup
