local config = require("nvim.config")
local switch = require("nvim.pickers.switch")

---@class snacks.picker
---@field tab snacks.Picker

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
      local workspace = config.active_pane and config.active_pane.workspace

      for _, i in ipairs(config.flat_panes) do
        if i.workspace == workspace and not traversed[i.tab_name] then
          traversed[i.tab_name] = i.tab_name
          table.insert(items, {
            id = i.tab_id,
            name = i.tab_name,
            text = string.format("%s %s", switch.lazy_statuses[i.lazy_status], i.tab_name),
            value = i,
          })
        end
      end

      return items
    end,
  }
)

return M
