local orgtasks = require("nvim.pickers.org.tasks")
local files = require("nvim.pickers.org.files")
local procs = require("nvim.pickers.procs")
local switch = require("nvim.pickers.switch")

---@type VnixPickers
local M = {
  switch = switch,
  procs = procs,
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
