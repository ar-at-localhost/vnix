local env = require("common.env")
local tbl = require("common.tbl")
local home = env.get_env("HOME")

---@class WorkspaceTempates
---@field blank VnixWorkspaceTemplate
---@field dev VnixWorkspaceTemplate
local M = {} ---@type WorkspaceTempates

M.blank = {
  type = "workspace",
  name = "Blank",
  desc = "An empty workspace",
  id = "blank",

  ---@param opts VnixWorkspaceTemplateOptsBase
  ---@param base VnixWorkspace?
  apply = function(opts, base)
    local name = opts.name or (base and base.name)
    local cwd = opts.cwd or (base and base.cwd) or home

    ---@type VnixWorkspace
    local blank = {
      name = name,
      cwd = cwd,
      tabs = {
        {
          name = opts.name,
          pane = {
            name = opts.name,
          },
        },
      },
    }

    return blank
  end,

  form = {
    title = "Create Workspace",
    desc = "Please provide following details for new workspace.",
    name = "DEV",
    id = "dev",
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
        default = home or "",
      },
    },
  },
}

---@class DEVWorkspaceTemplateOpts :VnixWorkspaceTemplateOptsBase
---@field editor_cmd table? Editor command
M.dev = {
  type = "workspace",
  name = "DEV",
  desc = "A workspace for development projects",
  id = "dev",

  ---@param opts DEVWorkspaceTemplateOpts
  ---@param base VnixWorkspace?
  apply = function(opts, base)
    local editor = opts.editor_cmd or { ":", "nvim" }
    local name = opts.name or (base and base.name)
    local cwd = opts.cwd or (base and base.cwd) or home

    --- @type VnixWorkspace
    local dev_workspace = {
      name = name,
      cwd = cwd,
      tabs = {
        -- Editor Tab
        {
          name = "Editor",
          pane = {
            name = "Editor",
            args = editor,
            meta = {
              layout = "dev",
            },
          },
        },

        -- Term Tab
        {
          name = "Term",
          pane = {
            name = "Term",
            meta = {
              layout = "dev",
            },
          },
        },

        -- VSplit
        -- -- Left Split
        {
          name = "VSplit",
          pane = {
            name = "Left",
            meta = {
              layout = "dev",
            },

            right = {
              name = "Right",
              meta = {
                layout = "dev",
              },
            },
          },
        },

        -- HSplit
        -- -- Top Split
        {
          name = "HSplit",
          pane = {
            name = "Top",
            meta = {
              layout = "dev",
            },

            bottom = {
              name = "Bottom",
              meta = {
                layout = "dev",
              },
            },
          },
        },

        -- Grid Tab
        {
          name = "Grid",
          pane = {
            name = "Left",
            meta = { layout = "dev" },
            first_split = "Right",

            right = {
              name = "Right",
              meta = { layout = "dev" },

              bottom = {
                name = "Bottom Right",
                meta = { layout = "dev" },
              },
            },

            bottom = {
              name = "Bottom Left",
              meta = { layout = "dev" },
            },
          },
        },
      },
    }

    return tbl.deep_merge(base, dev_workspace)
  end,

  form = {
    title = "Create Workspace",
    desc = "Please provide following details for new workspace.",
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
        default = home or "",
      },
      {
        key = "editor_cmd",
        title = "Editor command",
        default = "nvim",
      },
    },
  },
}

return M
