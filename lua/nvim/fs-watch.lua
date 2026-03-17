local config = require("nvim.config")
local fs = require("common.fs")
local M = {}

local function handle_runtime(filepath)
  local data = fs.read_json(filepath)
  if data then
    ---@cast data VnixRuntime
    pcall(require("nvim.state").process, data.panes)
    config.workspaces = data.workspaces
    config.active_pane = data.active_pane
    config.procs = data.procs

    if config.pickers.procs and config.pickers.procs.state then
      config.pickers.procs.state:refresh()
    end
  end
end

function M.setup_vnix()
  if config.watchers["vnix"] then
    return
  end

  local handle = vim.uv.new_fs_event()

  if not handle then
    return
  end

  handle:start(
    config.vnix_dir,
    { recursive = false },
    vim.schedule_wrap(function(err, filename, events)
      if err then
        vim.notify("Watch error: " .. err, vim.log.levels.ERROR)
        return
      end

      if not filename or not events.change then
        return
      end

      local filepath = string.format("%s/%s", config.vnix_dir, filename)

      if filename == "runtime.json" then
        handle_runtime(filepath)
      elseif filename == "req.json" then
        local data = fs.read_json(filepath)
        if data then
          pcall(require("nvim.req").handle_request, data)
        end
      end
    end)
  )

  -- Cleanup on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if handle and handle:is_active() then
        handle:close()
      end
    end,
  })

  handle_runtime(string.format("%s/%s", config.vnix_dir, "runtime.json"))
  config.watchers["vnix"] = handle
end

function M.setup()
  M.setup_vnix()
end

return M
