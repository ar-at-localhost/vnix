local config = require("nvim.config")
local org = require("nvim.org")
local resp = require("nvim.resp")
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
  ---@param _ SnacksOrgTasksPickerItem
  ---@param picker snacks.Picker
  ---@param action SnacksOrgTasksPickerAction
  local function hook(_, picker, action)
    ---@type UIMessageOrgRespData
    local data = {}

    if action == "toggle_clock" then
      org.sync_clock()
      data.sync_clock = true
      resp.write(resp.create_from_req(arg, data), true)
    end

    pcall(function()
      picker:close()
    end)
  end

  ---@type SnacksOrgTasksPickerConfig
  ---@diagnostic disable-next-line: missing-fields
  local opts = {
    node = nil,
    level = 1,
    dirs = {
      config.vnix_dir,
    },
    hooks = {
      after = {
        ["toggle_clock"] = function(i, p)
          hook(i, p, "toggle_clock")
        end,
      },
    },
  }

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
