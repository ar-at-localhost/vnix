---@alias VnixPicker snacks.picker.Config
---@alias VnixPickers table<VnixPickerSources, VnixPicker>
---@alias VnixPickerSources VnixPickerSearchSources | VnixPickerOrgSources
---@alias VnixPickerOrgSources 'orgtasks' | 'orgfiles'
---@alias VnixPickerSearchSources 'pane' | 'tab' | 'workspace'

---@alias VnixActivePicker VnixActivePickerBase | VnixOrgTasksActivePicker

---@class VnixActivePickerBase
---@field source VnixPickerSearchSources
---@field state unknown?

---@class VnixActivePickers
---@field switch? VnixActivePicker
---@field orgtasks? VnixOrgTasksActivePicker
---@field orgfiles? VnixOrgFilesActivePicker
