local M = {}

--- @class DevTemplateOptions workspace Template Overrides
--- @field cwd? string workspace current working directory
--- @field editor_cmd? table the command to run on editor tab/pane

--- @param name string The name of the workspace
--- @param offset? number The offset to calculate the links
--- @param overrides? DevTemplateOptions Overrides
function M.workspace(name, offset, overrides)
  local opts = overrides or {}
  local editor = opts.editor_cmd or { "nvim" }
  local cwd = opts.cwd or nil
  offset = offset or 0
  assert(offset + 2 >= 1, "Pane index must be >= 1")

  --- @type PaneSpec[]
  local dev_workspace = {
    -- Editor Tab
    {
      workspace = name,
      tab = "Editor",
      name = "Editor",
      cwd = cwd,
      args = editor,
      args_mode = "sl",
      env = {},
      extras = {
        layout = "dev",
      },
    },

    -- Term Tab
    {
      workspace = name,
      tab = "Term",
      name = "Term",
      cwd = cwd,
      args_mode = "sl",
      extras = {
        layout = "dev",
      },
    },

    -- VSplit
    -- -- Left Split
    {
      workspace = name,
      tab = "VSplit",
      name = "VSplit Left",
      right = offset + 4,
      first = "right",
      cwd = cwd,
      args_mode = "sl",
      extras = {
        layout = "dev",
      },
    },

    -- -- Right Split
    {
      workspace = name,
      tab = "VSplit",
      name = "VSplit Right",
      left = offset + 3,
      cwd = cwd,
      args_mode = "sl",
      extras = {
        layout = "dev",
      },
    },

    -- HSplit
    -- -- Top Split
    {
      workspace = name,
      tab = "HSplit",
      name = "HSplit Top",
      bottom = offset + 6,
      first = "bottom",
      cwd = cwd,
      args_mode = "sl",
      extras = {
        layout = "dev",
      },
    },
    -- -- Bottom Split
    {
      workspace = name,
      tab = "HSplit",
      name = "HSplit Bottom",
      cwd = cwd,
      top = offset + 5,
      args_mode = "sl",
      extras = {
        layout = "dev",
      },
    },

    -- Grid
    -- -- Top Left
    {
      workspace = name,
      tab = "Grid",
      name = "Top Left",
      cwd = cwd,
      first = "right",
      right = offset + 8,
      bottom = offset + 10,
      args_mode = "sl",
      extras = {
        layout = "dev",
      },
    },
    -- -- Top Right
    {
      workspace = name,
      tab = "Grid",
      name = "Top Right",
      cwd = cwd,
      left = offset + 7,
      first = "bottom",
      bottom = offset + 9,
      lazy = true,
      args_mode = "sl",
      extras = {
        layout = "dev",
      },
    },
    -- -- Bottom Right
    {
      workspace = name,
      tab = "Grid",
      name = "Bottom Right",
      cwd = cwd,
      top = offset + 8,
      args_mode = "sl",
      extras = {
        layout = "dev",
      },
    },
    -- -- Bottom Left
    {
      workspace = name,
      tab = "Grid",
      name = "Bottom Left",
      cwd = cwd,
      top = offset + 7,
      args_mode = "sl",
      extras = {
        layout = "dev",
      },
    },
  }

  return dev_workspace
end

return M
