local common = require("common")

local function b64(s)
  return vim.fn.system({ "base64", "-w0" }, s):gsub("\n", "")
end

local M = {}

---Close back to the last pane of Vnix
---@param type UIMessageType
---@param data? unknown
---@return UIMessageRespBase
function M.create(type, data)
  return {
    type = type,
    id = 0,
    timestamp = "",
    data = data,
  }
end

---Close back to the last pane of Vnix
---@param req UIMessageReqBase
---@return UIMessageRespBase
function M.create_from_req(req, data)
  return {
    type = req.type,
    id = req.id,
    timestamp = req.timestamp,
    data = data,
  }
end

---Close back to the last pane of Vnix
---@param id? number
function M.switch(id)
  if not id then
    local req = {
      type = "switch",
      id = 0,
      timestamp = "",
      data = nil,
      return_to = id or 1, -- FIXME: It should be `return_to`
    }

    M.write(common.create_resp(req, 1))
  end
end

---Write response from Vnix Nvim to Vnix
---@param response UIMessageRespBase
---@param return_to_dashboard? boolean
function M.write(response, return_to_dashboard)
  local json = vim.json.encode(response)
  local osc = string.format("\x1b]1337;SetUserVar=%s=%s\x07", common.VNIX_USER_VAR_NAME, b64(json))

  io.stdout:write(osc)
  io.stdout:flush()

  if return_to_dashboard then
    require("nvim.dashboard")()
  end
end

return M
