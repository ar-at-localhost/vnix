local config = require("nvim.config")
local switch = require("nvim.pickers.switch")

---@class snacks.picker
---@field workspace snacks.Picker

---@type snacks.picker.Config
local M = vim.tbl_extend(
  "force",
  switch,
  ---@type snacks.picker.Config
  {
    format = "text",
    auto_confirm = false,
    auto_close = false,
    layout = "select",
    preview = function()
      return false
    end,

    finder = function()
      local traversed = {}
      local items = {}

      for _, v in ipairs(config.flat_panes) do
        if not traversed[v.workspace] then
          traversed[v.workspace] = v.workspace
          table.insert(items, {
            id = v.workspace,
            name = v.workspace,
            text = string.format("%s %s", switch.lazy_statuses[v.lazy_status], v.workspace),
            value = v,
          })
        end
      end

      return items
    end,
  }
)

return M
