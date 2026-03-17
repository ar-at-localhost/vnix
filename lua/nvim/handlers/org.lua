local config = require("nvim.config")
local M = {}

local function get_org_dir()
  local workspace_name = config.active_pane and config.active_pane.workspace
  for _, v in ipairs(config.workspaces) do
    if v.name == workspace_name and v.orgpath and type(v.orgpath) == "string" then
      return string.format("%s/%s", v.cwd, v.orgpath)
    end
  end
end

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

  local orgdir = get_org_dir()
  if orgdir then
    opts.dirs = { orgdir }
  end

  if not arg.data then
    arg.data = "tasks"
  end

  if arg.data == "tasks" then
    Snacks.picker.orgtasks(opts)
  else
    Snacks.picker.orgfiles(opts)
  end
end

return M
