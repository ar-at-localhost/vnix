local workspace = require("nvim.pickers.workspace")
local pane = require("nvim.pickers.pane")
local tab = require("nvim.pickers.tab")
local orgtasks = require("nvim.pickers.org.tasks")
local files = require("nvim.pickers.org.files")

---@type VnixPickers
local M = {
  workspace = workspace,
  tab = tab,
  pane = pane,
  orgtasks = orgtasks,
  orgfiles = files,
}

local function setup()
  for k, v in pairs(M) do
    if not Snacks.picker.sources[k] then
      Snacks.picker.sources[k] = v
    end
  end
end

return setup
