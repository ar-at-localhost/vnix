local M = {}

---@param req UIMessageReqBase
function M.handle_request(req)
  local config = require("nvim.config")
  config.return_to = req.return_to or config.return_to or 2

  -- FIXME: Make conditional for debug
  table.insert(config.rpc, {
    req = req,
  })

  if req.type == "create" then
    ---@cast req UIMessageCreateReq
    require("nvim.handlers.create").handle(req)
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
