local resp = require("nvim.resp")
local config = require("nvim.config")

local M = {}

---@param req? UIMessageSwitchReq | true
function M.handle(req)
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
      resp.write(resp.create_from_req(req, vnix.return_to))
      return
    end
  end

  local picker = config.pickers.switch

  if not picker then
    picker = "pane"
    config.pickers.switch = picker
  end

  if picker then
    Snacks.picker.resume({
      source = picker,
    })
  end
end

return M
