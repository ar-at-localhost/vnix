---@class StateModule
---@field process fun(data: VnixStateFlatEntry[]):nil Process the state file

---@type StateModule
local M = {
  process = function(data)
    local tbl = require("common.tbl")
    local vnix = require("nvim.config")
    vnix.state = data

    do
      local dev_workspaces = {}

      for i, v in ipairs(vnix.state) do
        if v.meta and v.meta["layout"] and v.meta["layout"] == "dev" then
          dev_workspaces[v.workspace] = {
            idx = i,
            cwd = v.cwd,
          }
        end
      end

      if not tbl.deep_equal(dev_workspaces, vnix.dev_workspaces) then
        vnix.dev_workspaces = dev_workspaces
        pcall(function()
          local orgmode = require("orgmode")
          orgmode.destroy()

          local org_paths = vim.tbl_map(function(value)
            ---@cast value { cwd: string; idx: number }
            return value.cwd .. "/orgfiles/**/*.org"
          end, dev_workspaces)

          ---@type string[]
          org_paths = vim.tbl_values(org_paths)
          table.insert(org_paths, vnix.vnix_dir .. "/orgfiles/**/*.org")

          orgmode.setup({
            org_agenda_files = org_paths,
            org_default_notes_file = vnix.vnix_dir .. "/notes.org",
          })
        end)
      end
    end
  end,
}

return M
