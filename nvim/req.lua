local M = {}

---@param req UIMessageReqBase
function M.handle_request(req)
  local vnix = require("nvim.config")
  vnix.return_to = req.return_to or vnix.return_to or 2

  if req.type == "create" then
    require("nvim.handlers.create").handle()
  elseif req.type == "debug" then
    ---@cast req UIMessageDebugReq
    require("nvim.handlers.debug").handle(req)
  elseif req.type == "inspect" then
    ---@cast req UIMessageLaunchReq
    require("nvim.handlers.inspect").handle(req)
  elseif req.type == "launch" then
    ---@cast req UIMessageLaunchReq
    require("nvim.handlers.launch").handle()
  elseif req.type == "switch" then
    ---@cast req UIMessageSwitchReq
    require("nvim.handlers.switch").handle(req)
  end
end

return M
