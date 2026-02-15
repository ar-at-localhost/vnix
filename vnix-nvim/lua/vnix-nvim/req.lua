local M = {}

---@param req UIMessageReqBase
function M.handle_request(req)
  local vnix = require("vnix-nvim.vnix")
  vnix.return_to = req.return_to or vnix.return_to or 2

  if req.type == "switch" then
    ---@cast req UIMessageSwitchReq
    require("vnix-nvim.handlers.switch").handle(req)
  elseif req.type == "launch" then
    ---@cast req UIMessageLaunchReq
    require("vnix-nvim.handlers.launch").handle()
  elseif req.type == "timesheet" then
    ---@cast req UIMessageTTReq
    require("vnix-nvim.handlers.time-tracker").handle(req)
  elseif req.type == "inspect" then
    ---@cast req UIMessageLaunchReq
    require("vnix-nvim.handlers.inspect").handle(req)
  end
end

return M
