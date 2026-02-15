---@class VnixNvimUtils
local M = {} ---@type VnixNvimUtils

function M.close_all_wins()
  local wins = vim.api.nvim_list_wins()
  for _, w in ipairs(wins) do
    pcall(vim.api.nvim_win_close, w, true)
  end
end

return M
