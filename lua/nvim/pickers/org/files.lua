local config = require("nvim.config")
local orgmode = require("orgmode")

config.pickers.orgfiles = config.pickers.orgfiles
  or {
    source = "orgfiles",
    state = {
      format_title = "both",
    },
  }

---@class VnixOrgFilesActivePicker
---@field source 'orgfiles'
---@field state VnixOrgFilesPickerState

---@class VnixOrgFilesPickerItem
---@field text string
---@field file string
---@field orgfile OrgFile

---@class VnixOrgFilesPickerState
---@field workspace? 'all' | string
---@field action? fun(picker: snacks.Picker, item: VnixOrgFilesPickerItem): boolean? Return `true` to prevent close of picker
---@field format_title? 'title' | 'filename' | 'both'
local state = config.pickers.orgfiles.state ---@type VnixOrgFilesPickerState

---@class VnixFilePicker :snacks.picker.proc.Config
local orgfiles_picker = {
  finder = function()
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

    return items
  end,

  ---@param item snacks.picker.Item
  transform = function(item)
    return true
  end,

  ---@param item VnixOrgFilesPickerItem
  ---@param picker snacks.Picker
  format = function(item, picker)
    if state.format_title == "filename" then
      ---@diagnostic disable-next-line: param-type-mismatch
      return Snacks.picker.sources.files.format(item, picker)
    elseif state.format_title == "title" then
      return {
        { " ", "@org.headline.level1" },
        { item.orgfile:get_title(), "@org.headline.level2" },
      }
    else
      local title = item.orgfile:get_title()
      if title == item.orgfile.filename then
        title = ""
      end

      return {
        { " ", "@org.headline.level1" },
        { title, "@org.headline.level1" },
        { " <" },
        { item.orgfile.filename, "@org.headline.level2" },
        { ">" },
      }
    end
  end,

  ---@param picker snacks.Picker
  ---@param item VnixOrgFilesPickerItem
  confirm = function(picker, item)
    if not state.action then
      ---@diagnostic disable-next-line: param-type-mismatch
      return picker:action("edit")
    end

    local res = state.action(picker, item)
    if not res then
      pcall(function()
        picker:close()
      end)
    end
  end,
}

---@type VnixFilePicker
local M = vim.tbl_extend("force", Snacks.picker.sources.files, {
  ft = "org",
}, orgfiles_picker)

return M
