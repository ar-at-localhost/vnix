local api = require("orgmode.api")
require("nvim.org.headline")
---@class VnixOrgHeadline
local M = {} ---@type VnixOrgHeadline

local function notify(msg)
  Snacks.notify(msg or "Failed to acquire task!", { level = "error", title = "Vnix Org" })
end

---@param node OrgHeadline
---@param check_node? fun(node: OrgHeadline): string?
---@param check_file? fun(file: OrgApiFile): string?
---@return OrgApiFile? file
function M.resolve_file_api(node, check_node, check_file)
  if not node or not node.file then
    return notify()
  end

  local err = check_node and check_node(node)
  if err then
    return notify(err)
  end

  local file = api.load(node.file.filename)
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

  return headline
end

---@param priority string
function M.priority_to_integer(priority)
  if not priority or priority == "" then
    return 999
  end

  return string.byte(priority) - string.byte("A")
end

return M
