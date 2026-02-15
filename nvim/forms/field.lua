local config = require("nvim.config")
---
---@class VnixFormField
---@field new fun(self, opts:VnixFormFieldOpts): VnixFormField
---@field _field VnixNvimFormField
---@field _buf integer
---@field _offset integer
---@field _mark integer
local VnixFormField = {}
VnixFormField.__index = VnixFormField

---@class VnixFormFieldOpts
---@field field VnixNvimFormField
---@field buf integer
---@field line? integer
---@field emark? integer

---Create new VnixFormField
---@param opts VnixFormFieldOpts
---@return VnixFormField
function VnixFormField:new(opts)
  local o = setmetatable({}, self)
  o._field = opts.field
  o._buf = opts.buf
  o._offset = opts.line or 0

  o:_init()
  return o
end

---@private
function VnixFormField:_init()
  local default_value = self._field.default or ""
  vim.api.nvim_buf_set_lines(self._buf, self._offset, self._offset, false, {
    default_value,
  })
  local title = self._field.title or "Input"
  local title_len = string.len(title)
  local virt_line_text = string.rep("-", 4)
    .. string.rep(" ", 2)
    .. title
    .. string.rep(" ", 2)
    .. string.rep("-", 50 - title_len)

  self._mark = vim.api.nvim_buf_set_extmark(self._buf, config._ns, self._offset, 0, {
    virt_text = {
      { virt_line_text, "Comment" },
    },
  })
end

---@private
function VnixFormField:_init_events() end

---@private
function VnixFormField:_get_pos()
  local pos = vim.api.nvim_buf_get_extmark_by_id(self._buf, config._ns, self._mark, {})
  return pos
end

function VnixFormField:get_value()
  local pos = self:_get_pos()
  local lines = vim.api.nvim_buf_get_lines(self._buf, pos[1], pos[1] + 1, false)
  return lines[1]
end

return VnixFormField
