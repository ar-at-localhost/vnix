local config = require("nvim.config")
local M = {}

---@param arg UIMessageOrgReq
---@diagnostic disable-next-line: unused-local
function M.handle(arg)
  local opts = {
    node = nil,
    level = 1,
    dirs = {
      config.vnix_dir,
    },
  }
  ---@type string?

  if config.active_pane and config.active_pane.meta and config.active_pane.meta.layout == "dev" then
    for i, v in pairs(config.dev_workspaces) do
      if i == config.active_pane.workspace then
        opts.dirs = { v.cwd }
      end
    end
  end

  Snacks.picker.orgtasks(opts)
end

return M
