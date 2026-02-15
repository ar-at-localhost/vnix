local config = require("nvim.config")
local utils = require("nvim.utils")

local function run()
  utils.close_all_wins()
  if not config.dashboard then
    local dashboard = require("snacks.dashboard")
    config.dashboard = dashboard.open({
      sections = {
        section = "header",
      },
      formats = {},
      preset = {
        header = [[
    ██╗   ██╗███╗   ██╗██╗██╗  ██╗
    ██║   ██║████╗  ██║██║╚██╗██╔╝
    ██║   ██║██╔██╗ ██║██║ ╚███╔╝ 
    ╚██╗ ██╔╝██║╚██╗██║██║ ██╔██╗ 
     ╚████╔╝ ██║ ╚████║██║██╔╝ ██╗
      ╚═══╝  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝]],
      },
    })
  end
end

return run
