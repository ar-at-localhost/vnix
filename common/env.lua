---@class EnvUtils
---@field ensure_nvim fun(desc?: string) Safely check for nvim environment
local M = {} ---@type EnvUtils

function M.ensure_nvim(desc)
  if type(vim) ~= "table" or type(vim.api) ~= "table" then
    error(string.format("%s: Neovim not detected!", desc or "Oops"), 2)
  end
end

return M
