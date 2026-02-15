local function b64(s)
  return vim.fn.system({ "base64", "-w0" }, s):gsub("\n", "")
end

---Write response from Vnix Nvim to Vnix
---@param response UIMessageRespBase
---@param return_to_dashboard? boolean
local function resp(response, return_to_dashboard)
  local common = require("vnix-common")

  local json = vim.json.encode(response)
  local osc = string.format("\x1b]1337;SetUserVar=%s=%s\x07", common.VNIX_USER_VAR_NAME, b64(json))

  io.stdout:write(osc)
  io.stdout:flush()

  if return_to_dashboard then
    require("vnix-nvim.dashboard")()
  end
end

return resp
