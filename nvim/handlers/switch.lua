local resp = require("nvim.resp")
local M = {}

---Convert pane state to Snacks Picker item
---@param id number
---@param pane VnixStateFlatEntry
---@return snacks.picker.Item
local function to_item(id, pane)
  local str = require("common.str")

  ---@type snacks.picker.Item
  local item = {
    id = id,
    idx = id,
    score = 0,

    text = string.format(
      "%s > %s > %s",
      str.pad(pane.workspace, 16),
      str.pad(pane.tab_name, 16),
      str.pad(pane.pane_name, 16)
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
---@param data VnixStateFlatEntry[]
---@return snacks.picker.Item[]
local function to_items(data)
  ---@type VnixStateFlatEntry[]
  local out = {}

  for _, v in ipairs(data) do
    table.insert(out, to_item(v.pane_id, v))
  end

  return out
end

---@param req? UIMessageSwitchReq | true
function M.handle(req)
  local common = require("common")
  local vnix = require("nvim.config")
  local quick_return = req == true

  if not req or quick_return then
    req = {
      type = "switch",
      id = 0,
      timestamp = "",
      data = nil,
      return_to = vnix.return_to,
    }

    if quick_return then
      resp.write(common.create_resp(req, vnix.return_to))
      return
    end
  end

  local SnacksPicker = require("snacks.picker")
  ---@type snacks.Picker | nil
  local items = to_items(vnix.state)

  local picker = SnacksPicker.pick(nil, {
    items = items,
    format = "text",
    preview = "preview",
    auto_confirm = false,
    confirm = function(self, item)
      resp.write(common.create_resp(req, item.id))
      self:close()
    end,
  })

  if picker then
    picker:show()
  end
end

return M
