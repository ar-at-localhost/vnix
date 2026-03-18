local config = require("nvim.config")
local time = require("common.time")
local fs = require("common.fs")
require("nvim.org.headline")
local helpers = require("nvim.org.helpers")

---@class VnixOrgMode
local M = {} ---@type VnixOrgMode

function M.setup()
  local orgmode = require("orgmode")
  orgmode.destroy()

  local Path = require("plenary.path")
  local org_paths = { string.format("%s/orgfiles/**/*.org", config.vnix_dir) }
  local org_notes_path = Path:new(config.vnix_dir):joinpath("orgfiles", "notes.org").filename

  for _, w in pairs(config.workspaces) do
    if w.orgpath and type(w.orgpath) == "string" then
      local orgpath = (w.orgpath or ""):gsub("/$", "")
      table.insert(org_paths, string.format("%s/%s/**/*.org", w.cwd, orgpath))
    end
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

  config.timers = config.timers or {}
  if not config.timers.status then
    local timer = vim.uv.new_timer()
    if timer then
      config.timers.status = timer
      timer:start(0, 50 * 1000, function()
        vim.schedule(function()
          M.sync_clock()
        end)
      end)
    end
  end
end

function M.sync_clock()
  pcall(function()
    config.status = config.status or {}
    config.status.task = nil

    local active, _, headline = helpers.get_active_clock()
    if active and headline then
      config.status.task = {
        title = headline:get_title(),
        since = active.start_time.timestamp,
        formatted = time.format_hhmm(time.now_unix() - (active.start_time.timestamp or 0)),
      }
    end

    fs.write_json(string.format("%s/status.json", config.vnix_dir), config.status)
  end)
end

return M
