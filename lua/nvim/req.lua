local config = require("nvim.config")
local M = {}

---@param req UIMessageReqBase
function M.handle_request(req)
  if req.type ~= "launch" and req.id <= config.last_known_req then
    return
  else
    config.last_known_req = req.id
    config.return_to = req.return_to or config.return_to or 2
  end

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
  elseif req.type == "persist" then
    ---@cast req UIMessagePersistReq
    require("nvim.handlers.persist").handle(req)
  elseif req.type == "rename" then
    ---@cast req UIMessageRenameReq
    require("nvim.handlers.rename").handle(req)
  elseif req.type == "switch" then
    ---@cast req UIMessageSwitchReq
    require("nvim.handlers.switch").handle(req)
  end
end

return M
