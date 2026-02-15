local resp = require("nvim.resp")
local M = {}

---@param req UIMessageReqBase
function M.handle(req)
  local vnix = require("nvim.config")
  local SnacksPicker = require("snacks.picker")

  ---@type snacks.Picker | nil
  local picker = SnacksPicker.pick("files", {
    cwd = vnix.vnix_dir,
    auto_confirm = false,
    ft = "json",

    confirm = function(self)
      resp.write(resp.create_from_req(req, nil))
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
