local M = {}

local function show_timesheet()
  local vnix = require("vnix-nvim.vnix")
  if not vnix.timesheet then
    vim.notify("Timesheet is not ready.", "warn")
    return
  end

  vim.cmd("tabnew " .. vim.fn.fnameescape(vnix.timesheet))
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = ""
  vim.bo[buf].swapfile = false
  vim.cmd("filetype detect")
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      require("vnix-nvim.dashboard")()
    end,
  })
end

---@param req UIMessageTTReq
function M.handle(req)
  local vnix = require("vnix-nvim.vnix")
  local activity = vnix.activity
  local on = activity.tt

  if req.data == "menu" then
    local opts = {
      {
        label = on and "Stop" or "Start",
        action = on and "stop" or "start",
      },
      {
        label = "View Timesheet",
        action = "timesheet",
      },
      {
        label = "Reset",
        action = "reset",
      },
    }

    vim.ui.select(opts, {
      prompt = string.format("Time tracker is %s. What to do?", on and "running" or "stopped"),
      format_item = function(item)
        return item.label
      end,
    }, function(item)
      if not item then
        return
      end

      if item.action == "timesheet" then
        show_timesheet()
        return
      end

      local common = require("vnix-common")
      local resp = require("vnix-nvim.resp")
      resp(common.create_resp(req, item.action))
    end)
  elseif req.data == "sheet" then
    show_timesheet()
  end
end

return M
