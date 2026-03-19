local orgmode = require("orgmode")
local Promise = require("orgmode.utils.promise")
local api = require("orgmode.api")
---@class VnixOrgHeadline
local M = {} ---@type VnixOrgHeadline

local function notify(msg)
  Snacks.notify(msg or "Failed to acquire task!", { level = "error", title = "Vnix Org" })
end

---Resolve API File by Headline or filename
---@param filename_or_headline OrgHeadline | string
---@param check_node? fun(node: OrgHeadline): string?
---@param check_file? fun(file: OrgApiFile): string?
---@return OrgApiFile? file
function M.resolve_file_api(filename_or_headline, check_node, check_file)
  local filename = ""
  local err

  if type(filename_or_headline) == "string" then
    filename = filename_or_headline
  else
    if not filename_or_headline or not filename_or_headline.file then
      return notify()
    end

    err = check_node and check_node(filename_or_headline)
    if err then
      return notify(err)
    end

    filename = filename_or_headline.file.filename
  end

  local file = api.load(filename)
  if not file or not file.filename then
    return notify()
  end

  err = check_file and check_file(file)
  if err then
    return notify(err)
  end

  return file
end

---@param node OrgHeadline
---@param check_node? fun(node: OrgHeadline): string?
---@param check_file? fun(file: OrgApiFile): string?
---@param check_headline? fun(headline: OrgApiHeadline): string?
---@return OrgApiHeadline? headline
---@return OrgApiFile? file
function M.resolve_headline_api(node, check_node, check_file, check_headline)
  local file = M.resolve_file_api(node, check_node, check_file)
  if not file then
    return
  end

  local range = node:get_range()
  local headline = range and file:get_headline_on_line(range.start_line)
    or file:get_closest_headline()
  if not headline then
    return notify("Failed to acquire headline!")
  end

  local err = check_headline and check_headline(headline)
  if err then
    return notify(err)
  end

  return headline, file
end

---Get active clock
---@return table? clock_info
---@return OrgLogbook? log_book
---@return OrgHeadline? headline
function M.get_active_clock()
  local headline = orgmode.files:get_clocked_headline()
  if headline then
    local log_book = headline:get_logbook()
    if log_book then
      return log_book:get_active(), log_book, headline
    end
  end
end

---@param keep OrgHeadline? Keep this headline clocked in
function M.clock_out_all(keep)
  return Promise.resolve():next(function()
    local chain = Promise.resolve()

    for _, f in pairs(orgmode.files.files) do
      ---@cast f OrgFile
      local headlines = f:get_headlines()

      for _, h in ipairs(headlines) do
        local ha = M.resolve_headline_api(h)
        if ha and not M.is_same_headline(h, keep) then
          chain = chain:next(function()
            return ha:clock_out()
          end)
        end
      end
    end

    return chain
  end)
end

---@param a OrgHeadline?
---@param b OrgHeadline?
function M.is_same_headline(a, b)
  return a
    and b
    and a.file.filename == b.file.filename
    and a:get_range().start_line == b:get_range().start_line
end

---@param priority string
function M.priority_to_integer(priority)
  if not priority or priority == "" then
    return 999
  end

  return string.byte(priority) - string.byte("A")
end

return M
