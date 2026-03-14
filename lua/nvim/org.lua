local config = require("nvim.config")
local resp = require("nvim.resp")
local time = require("common.time")

---@class VnixOrgMode
local M = {} ---@type VnixOrgMode

function M.setup()
  local orgmode = require("orgmode")
  orgmode.destroy()

  local Path = require("plenary.path")
  local org_paths = { string.format("%s/orgfiles/**/*.org", config.vnix_dir) }
  local org_notes_path = Path:new(config.vnix_dir):joinpath("orgfiles", "notes.org").filename

  for _, w in pairs(config.dev_workspaces) do
    table.insert(org_paths, string.format("%s/orgfiles/**/*.org", w.cwd))
  end

  local Menu = require("org-modern.menu")
  orgmode.setup({
    org_agenda_files = org_paths,
    org_default_notes_file = org_notes_path,
    org_todo_keywords = config.org.keywords,

    ui = {
      menu = {
        handler = function()
          Menu:new():open()
        end,
      },
    },
  })

  require("org-bullets").setup()
  require("headlines").setup({
    markdown = {
      headline_highlights = false,
    },
  })

  local timer = vim.uv.new_timer()
  if timer then
    timer:start(0, 15 * 1000, function()
      vim.schedule(function()
        pcall(function()
          local headline = orgmode.files:get_clocked_headline()
          if headline then
            local log_book = headline:get_logbook()
            if log_book then
              local active = log_book:get_active()
              if active then
                resp.write({
                  type = "status",
                  id = 0,
                  timestamp = "",
                  data = {
                    title = headline:get_title(),
                    since = active.start_time.timestamp,
                    formatted = time.format_hhmm(
                      time.now_unix() - (active.start_time.timestamp or 0)
                    ),
                  },
                  return_to = 0,
                }, false)
              end
            end
          end
        end)
      end)
    end)
  end
end

return M
