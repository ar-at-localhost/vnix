local workspace = require("nvim.pickers.workspace")
local pane = require("nvim.pickers.pane")
local tab = require("nvim.pickers.tab")
local tasks = require("nvim.pickers.org.tasks")

---@type VnixPickers
local M = {
  workspace = workspace,
  tab = tab,
  pane = pane,
  tasks = tasks,
}

local function setup()
  for k, v in pairs(M) do
    if not Snacks.picker.sources[k] then
      Snacks.picker.sources[k] = v
    end
  end
end

return setup
