local resp = require("nvim.resp")
local M = {}

---@param req UIMessageReqBase
function M.handle(req)
  local common = require("common")
  local vnix = require("nvim.config")
  local SnacksPicker = require("snacks.picker")

  ---@type snacks.Picker | nil
  local picker = SnacksPicker.pick("files", {
    cwd = vnix.vnix_dir,
    auto_confirm = false,
    ft = "json",

    confirm = function(self)
      resp.write(common.create_resp(req, nil))
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
