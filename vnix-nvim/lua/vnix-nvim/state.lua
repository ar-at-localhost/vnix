---@class StateModule
---@field process fun(data: PaneState[]):nil Process the state file

---@type StateModule
local M = {
  process = function(data)
    local common = require("vnix-common")
    local tbl = require("vnix-common.tbl")
    local vnix = require("vnix-nvim.vnix")
    vnix.state = data

    do
      local ok, err = pcall(function()
        local time = require("vnix-common.time")
        local state = require("vnix-common.state")

        local timesheet_file =
          string.format("%s/timesheet-%s.csv", vnix.vnix_dir, time.format_date())
        local csv = state.to_timesheet_csv(data)
        common.write_file(timesheet_file, csv)
        vnix.timesheet = timesheet_file
      end)

      if not ok then
        vim.notify("Error creating timesheet file: " .. tostring(err), vim.log.levels.ERROR)
      end
    end

    do
      local dev_workspaces = {}

      for i, v in ipairs(vnix.state) do
        if v.extras and v.extras["layout"] and v.extras["layout"] == "dev" then
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
