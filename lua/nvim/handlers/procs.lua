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

  if arg.data == "vnix" then
    opts.workspace = common.vnix_token
  elseif
    arg.data == "workspace"
    and config.active_pane
    and config.active_pane.meta
    and config.active_pane.meta.layout == "dev"
  then
    opts.workspace = config.active_pane.workspace
  end

  if not config.pickers.procs then
    config.pickers.procs = {
      source = "procs",
    }
  end

  local picker = config.pickers.procs.state

  if not picker then
    picker = Snacks.picker.procs(opts)
  end

  config.pickers.procs = {
    source = "procs",
    state = picker,
  }

  picker:show()
end

return M
