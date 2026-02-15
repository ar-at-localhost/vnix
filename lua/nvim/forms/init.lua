local VnixFormField = require("nvim.forms.field")
local str = require("common.str")
local tbl = require("common.tbl")
local config = require("nvim.config")

---@alias VnixFormSubmitHandler fun(result:unknown?)

---TODO: Keep the draft & let user resume if it wants
---@class VnixForm
---@field _spec VnixFormSpec
---@field _fields table<string, VnixFormField>
---@field _buf integer
---@field _line integer
---@field _help_lines_count integer
---@field _help_emark integer
---@field _keys table<string, snacks.win.Keys>
---@field _actions table<string, snacks.win.Action>
---@field _cb VnixFormSubmitHandler
local M = {} ---@type VnixForm
M.__index = M

---Create new VnixForm
---@param spec VnixFormSpec
---@param handler VnixFormSubmitHandler
---@return VnixForm
function M:new(spec, handler)
  local o = setmetatable({}, self)
  o._spec = spec
  o._fields = {}
  o._cb = handler

  ---@type VnixFormKeys
  local keys_copy = vim.tbl_deep_extend("force", {}, spec.keys or {})
  ---@type table<string, snacks.win.Keys>
  local out_keys = {}
  for k, v in pairs(keys_copy) do
    out_keys[k] = {
      v[1],
      function(win)
        local func = v[2]
        if func then
          func(o, win)
        end
      end,
      v[3],
    }
  end

  o._keys = tbl.merge_all({
    ["submit-form"] = {
      "<leader><CR>",
      "close",
      desc = "Submit form",
      mode = { "n" },
    },
  }, out_keys)

  ---@type table<string, snacks.win.Action>
  o._actions = {
    close = {
      action = function(win)
        local result = {}

        for _, spec_field in ipairs(o._spec.fields) do
          local field = o._fields[spec_field.key]

          if field and not spec_field.do_not_render then
            result[spec_field.key] = str.trim(field:get_value())
          else
            result[spec_field.key] = spec_field.value
          end
        end

        pcall(function()
          if vim.api.nvim_buf_is_valid(o._buf) then
            vim.api.nvim_buf_delete(o._buf, { force = true })
          end

          if win then
            win:close()
          end

          o._cb(result)
        end)
      end,
      desc = "Handle form submssion",
    },
  }

  o:_init()
  return o
end

function M:_init()
  local form = self._spec
  self._buf = vim.api.nvim_create_buf(false, true)
  local buf = self._buf

  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_name(buf, "/tmp/vnix-form-" .. os.time())

  self._line, self._help_lines_count = 0, 0
  for _, field in ipairs(form.fields) do
    if not field.key then
      error("Each field must've a key.")
    end

    if not field.do_not_render then
      self._fields[field.key] = VnixFormField:new({
        buf = buf,
        field = field,
        line = self._line,
      })

      self._line = self._line + 1
    end
  end

  self:_reset_help()
end

---Reset the help
---@param help VnixFormHelp
function M:reset_help(help)
  self._spec.help = help
  self:_reset_help()
end

---Run the form
---@param self VnixForm
function M:run()
  Snacks.win({
    title = self._spec.title or "Create Workspace",
    show = true,
    enter = true,
    buf = self._buf,
    bo = {
      buftype = "",
    },
    position = "float",
    border = "rounded",
    minimal = true,
    fixbuf = true,
    width = 60,
    height = self._line + self._help_lines_count + 3,
    wo = {
      spell = false,
      number = true,
      signcolumn = "auto",
    },
    keys = self._keys,
    actions = self._actions,
  })
end

function M:_reset_help()
  local form = self._spec

  if form.help then
    self._help_lines_count = #form.help
    self._help_emark = vim.api.nvim_buf_set_extmark(
      self._buf,
      config._ns,
      self._line,
      0,
      tbl.merge_all({
        virt_lines = form.help,
      }, self._help_emark and { id = self._help_emark } or {})
    )
  end
end

return M
