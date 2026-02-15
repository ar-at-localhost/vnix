local VnixFormField = require("nvim.forms.field")
local str = require("common.str")

---@class VnixNvimFormsMod
---@field run fun(form: VnixNvimForm, callback: fun(ok, result?: VnixNvimFormSubmission))
local M = {} ---@type VnixNvimFormsMod

function M.run(form, callback)
  local win ---@type snacks.win
  local buf = vim.api.nvim_create_buf(false, true)

  ---calls the callback
  ---@param result VnixNvimFormSubmission?
  local function cb(result)
    callback(result and true, result)
    if win then
      win:close()
    end
  end

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"

  ---@type table<string, VnixFormField>
  local fields = {}

  local line = 0
  for _, field in ipairs(form.fields) do
    fields[field.key] = VnixFormField:new({
      buf = buf,
      field = field,
      line = line,
    })

    line = line + 1
  end

  do
    --- TODO: Ensure cursor stays in one of the fields's input
  end

  win = Snacks.win({
    title = form.title or "Create Workspace",
    show = true,
    enter = true,
    buf = buf,
    position = "float",
    border = "rounded",
    minimal = true,
    fixbuf = true,
    width = 60,
    height = #form.fields + 3,
    keys = {
      ["submit-form"] = {
        "<leader><CR>",
        function()
          local result = {}

          for key, field in pairs(fields) do
            result[key] = str.trim(field:get_value())
          end

          cb(result)
        end,
        desc = "Submit form",
        mode = { "n" },
      },
    },

    on_close = function()
      vim.api.nvim_buf_delete(buf, { force = true })
      cb(nil)
    end,
  })
end

return M
