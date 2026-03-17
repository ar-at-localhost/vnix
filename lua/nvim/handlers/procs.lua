local config = require("nvim.config")
local common = require("common")
local M = {}

---@param arg UIMessageProcsReq
---@diagnostic disable-next-line: unused-local
function M.handle(arg)
  local opts = {
    workspace = nil,
  }
  ---@type string?

  if config.active_pane and config.active_pane.workspace then
    opts.workspace = config.active_pane.workspace
  else
    opts.workspace = common.vnix_token
  end

  if not config.pickers.procs then
    config.pickers.procs = {
      source = "procs",
    }
  end

  local picker = config.pickers.procs.state

  if not picker or not picker:is_active() then
    picker = Snacks.picker.procs(opts)
  end

  config.pickers.procs = {
    source = "procs",
    state = picker,
  }
end

return M
