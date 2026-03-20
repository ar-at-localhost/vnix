local config = require("nvim.config")
local switch = require("nvim.pickers.switch")

---@class snacks.picker
---@field pane snacks.Picker

---Convert pane state to Snacks Picker item
---@param id number
---@param pane VnixPaneFlat
---@return snacks.picker.Item
local function to_item(id, pane)
  local str = require("common.str")

  ---@type snacks.picker.Item
  local item = {
    id = id,
    idx = id,
    score = 0,

    text = string.format(
      "%s %s > %s > %s",
      switch.lazy_statuses[pane.lazy_status],
      str.pad(pane.workspace, 20),
      str.pad(pane.tab_name, 20),
      str.pad(pane.pane_name, 20)
    ),

    preview = {
      ft = "markdown",
      text = string.format(
        [[# Pane Info

**Workspace**: %s
**Tab**: %s
**Pane**: %s
]],
        pane.workspace,
        pane.tab_name,
        pane.pane_name
      ),
    },

    value = pane,
  }

  return item
end

---Convert pane state objects to Snacks Picker items
---@param data VnixPaneFlat[]
---@return snacks.picker.Item[]
local function to_items(data)
  ---@type VnixPaneFlat[]
  local out = {}

  for _, v in ipairs(data) do
    table.insert(out, to_item(v.pane_id, v))
  end

  return out
end

---@type snacks.picker.Config
local M = vim.tbl_extend(
  "force",
  switch,
  ---@type snacks.picker.Config
  {
    format = "text",
    preview = "preview",
    auto_confirm = false,
    auto_close = false,
    layout = "dropdown",

    finder = function()
      return to_items(config.flat_panes)
    end,
  }
)

return M
