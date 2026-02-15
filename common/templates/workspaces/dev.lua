local M = {}

--- @class DevTemplateOptions workspace Template Overrides
--- @field cwd? string workspace current working directory
--- @field editor_cmd? table the command to run on editor tab/pane

---@param opts DevTemplateOptions
function M.apply(opts)
  local editor = opts.editor_cmd or { ":", "nvim" }
  local cwd = opts.cwd or nil

  --- @type VnixPane[]
  local dev_workspace = {
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
      cwd = cwd,
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
      cwd = cwd,
      pane = {
        name = "VSplit Left",
        meta = {
          layout = "dev",
        },

        right = {
          name = "VSplit Right",
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
      cwd = cwd,
      pane = {
        name = "HSplit Top",
        meta = {
          layout = "dev",
        },

        bottom = {
          name = "HSplit Bottom",
          meta = {
            layout = "dev",
          },
        },
      },
    },

    -- Grid Tab
    {
      name = "Grid",
      cwd = cwd,
      pane = {
        name = "Top Left",
        meta = { layout = "dev" },
        first_split = "Right",

        right = {
          name = "Top Right",
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
  }

  return dev_workspace
end

function M.form()
  local env = require("common.env")
  env.ensure_nvim()
end

return M
