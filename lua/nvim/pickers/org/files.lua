local orgmode = require("orgmode")

---@class snacks.picker
---@field orgfiles SnacksOrgFilePickerOpts

---@class VnixOrgFilesActivePicker
---@field source 'orgfiles'
---@field picker snacks.Picker

---@class VnixOrgFilesPickerItem
---@field text string
---@field file string
---@field orgfile OrgFile

---@class SnacksOrgFilePickerOpts :snacks.picker.files.Config
---@field title_format? 'title' | 'filename' | 'both'
local orgfiles_picker_opts = {} ---@type SnacksOrgFilePickerOpts

---@param opts SnacksOrgFilePickerOpts
orgfiles_picker_opts.finder = function(opts)
  local items = {}

  pcall(function()
    local orgfiles = orgmode.files.files

    for path, file in pairs(orgfiles) do
      table.insert(items, {
        text = path,
        file = path,
        orgfile = file,
      })
    end
  end)

  if opts.dirs then
    for _, dir in pairs(opts.dirs) do
      items = vim.tbl_filter(function(item)
        return vim.startswith(item.file, vim.fs.normalize(dir))
      end, items)
    end
  end

  return items
end

---@param item VnixOrgFilesPickerItem
---@param picker snacks.Picker
orgfiles_picker_opts.format = function(item, picker)
  local opts = picker.opts ---@cast opts SnacksOrgFilePickerOpts
  if opts.title_format == "filename" then
    return {
      { " ", "@org.keyword.done" },
      { item.file, "@org.headline.level1" },
    }
  elseif opts.title_format == "title" then
    return {
      { " ", "@org.keyword.done" },
      { item.orgfile:get_title(), "@org.headline.level1" },
    }
  else
    local title = item.orgfile:get_title()
    if title == item.orgfile.filename then
      title = ""
    end

    return {
      { " ", "@org.keyword.done" },
      { title, "@org.headline.level1" },
      { " <" },
      { item.orgfile.filename, "@org.headline.level2" },
      { ">" },
    }
  end
end

---@type SnacksOrgFilePickerOpts
local M = vim.tbl_extend("force", {
  ft = "org",
  title_format = "both",
  auto_confirm = false,
  auto_close = false,
}, orgfiles_picker_opts)

return M
