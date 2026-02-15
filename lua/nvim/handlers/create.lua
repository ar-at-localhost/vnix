local templates = require("common.templates")
local env = require("common.env")
local resp = require("nvim.resp")

local home = env.get_env("HOME")

local M = {}

---Create a workspace
---@param req UIMessageCreateReq
function M.create_workspce(req)
  local layouts = templates.get_workspace_templates()
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
              name = item.name,
              opts = o,
            },
          },
        }

        local response = resp.create_from_req(req, data)
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

---@param req UIMessageCreateReq
function M.create_tab(req)
  local layouts = templates.get_tab_templates()
  vim.ui.select(
    layouts,
    {
      prompt = "Select a tab template:",
      format_item = function(item)
        ---@cast item VnixWorkspaceLayout
        return string.format("%s (%s)", item.name, item.desc)
      end,
    },

    ---@param item VnixTabTemplate
    function(item)
      ---cb
      ---@param t VnixTab
      local function next(t)
        ---@type UIMessageCreateTabRespData
        local data = {
          type = "tab",
          spec = t,
        }

        local response = resp.create_from_req(req, data)
        resp.write(response)
      end

      if not item.form then
        next({
          name = "Untitled",
          pane = {
            name = "Untitled",
            cwd = home,
          },
        })
      else
        item.form.title = item.form.title or "Workspace Details"

        require("nvim.forms").run(item.form, function(ok, result)
          if ok then
            ---@cast result VnixTabTemplateOptsBase
            next(item.apply(result))
          else
            resp.switch()
          end
        end)
      end
    end
  )
end

---Handle create Request
---@param req UIMessageCreateReq
function M.handle(req)
  if req.data == "workspace" then
    return M.create_workspce(req)
  elseif req.data == "tab" then
    return M.create_tab(req)
  end

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
      M.create_workspce(req)
    elseif item == "tab" then
      M.create_tab(req)
    end
  end)
end

return M
