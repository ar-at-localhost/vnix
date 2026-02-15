local function run()
  local dashboard = require("snacks.dashboard")
  dashboard.open({
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

return run
