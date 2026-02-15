local resp = require("vnix-nvim.resp")
local M = {}

---@param req UIMessageReqBase
function M.handle(req)
  local common = require("vnix-common")
  local vnix = require("vnix-nvim.vnix")
  local SnacksPicker = require("snacks.picker")

  ---@type snacks.Picker | nil
  local picker = SnacksPicker.pick("files", {
    cwd = vnix.vnix_dir,
    auto_confirm = false,
    ft = "json",

    confirm = function(self)
      resp(common.create_resp(req))
      if self then
        self:close()
      end
    end,
  })

  if picker then
    picker:show()
  end
end

return M
