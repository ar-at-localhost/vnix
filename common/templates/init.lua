local dev = require("common.templates.workspaces.dev")

---@class VnixTemplatesMode
---@field resolve_workspace fun(name: VnixWorkspaceLayoutName, opts: unknown): VnixTab[]
---@field get_workspace_layouts fun(): VnixWorkspaceLayout[]
local M = {} ---@type VnixTemplatesMode

function M.resolve_workspace(name, opts)
  if name == "dev" then
    return dev.apply(opts)
  end

  error("No such layout: " .. name)
end

--- @return VnixWorkspaceLayout[]
function M.get_workspace_layouts()
  --- @type VnixWorkspaceLayout[]
  local layouts = {
    {
      name = "scratch",
      desc = "Workspace with single tab / pane",
      form = {
        title = "Create new workspace",
        desc = "Please provide details.",
        fields = {
          {
            key = "name",
            title = "Name",
            default = "untitled",
            required = true,
          },
          {
            key = "cwd",
            title = "Current Working Directory",
          },
        },
      },
    },
    {
      name = "dev",
      desc = "A layout suitable for development",
      form = {
        fields = {
          {
            key = "name",
            title = "Name",
            default = "untitled",
            required = true,
          },
          {
            key = "cwd",
            title = "Current Working Directory",
            default = vim.fn.getenv("HOME") or "",
          },
          {
            key = "editor_cmd",
            title = "Editor command",
            default = "nvim",
          },
        },
      },
    },
  }

  return layouts
end

return M
