local config = require("nvim.config")
local procs = require("nvim.pickers.procs")
local M = {}

---@param arg UIMessageProcsReq
---@diagnostic disable-next-line: unused-local
function M.handle(arg)
  local opts = {
    source = "procs",
    workspace = arg.workspace,
    procs = arg.data,
  }

  local picker = config.pickers.procs
  if not picker then
    picker = Snacks.picker.procs(opts)
    config.pickers.procs = picker
    picker:show()
  else
    picker.opts = vim.tbl_extend("force", picker.opts, opts)
    picker:refresh()

    pcall(function()
      picker:show()
      picker:focus()
    end)
  end
end

return M
