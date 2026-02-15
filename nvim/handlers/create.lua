local templates = require("common.templates")
local resp = require("nvim.resp")

local M = {}

function M.create_workspce()
  local layouts = templates.get_workspace_layouts()
  vim.ui.select(
    layouts,
    {
      prompt = "Select a workspace template:",
      format_item = function(item)
        ---@cast item VnixWorkspaceLayout
        return string.format("%s (%s)", item.name, item.desc)
      end,
    },

    ---@param item VnixWorkspaceLayout
    function(item)
      ---cb
      ---@param o unknown?
      local function next(o)
        ---@type UIMessageCreateWorkspaceRespData
        local data = {
          type = "workspace",
          spec = {
            name = "",
            tabs = {},
            layout = {
              type = item.name,
              opts = o,
            },
          },
        }

        local response = resp.create("create", data)
        resp.write(response)
      end

      if not item.form then
        next()
      else
        item.form.title = item.form.title or "Workspace Details"

        require("nvim.forms").run(item.form, function(ok, result)
          if ok then
            next(result)
          else
            resp.switch()
          end
        end)
      end
    end
  )
end

function M.create_tab() end

function M.handle()
  local options = {
    "workspace",
    "tab",
  }

  vim.ui.select(options, {
    prompt = "Create new:",
    format_item = function(item)
      ---@cast item string
      local formatted = item:gsub("^%l", string.upper)
      return formatted
    end,
  }, function(item)
    if item == "workspace" then
      M.create_workspce()
    elseif item == "tab" then
      M.create_tab()
    end
  end)
end

return M
