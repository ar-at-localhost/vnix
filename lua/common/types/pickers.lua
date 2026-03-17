---@alias VnixPicker snacks.picker.Config
---@alias VnixPickers table<VnixPickerSources, VnixPicker>
---@alias VnixPickerSources VnixPickerSearchSources | VnixPickerOrgSources
---@alias VnixPickerOrgSources 'orgtasks' | 'orgfiles'
---@alias VnixPickerSearchSources 'pane' | 'tab' | 'workspace' | 'procs'

---@alias VnixActivePicker VnixActivePickerBase

---@class VnixActivePickerBase
---@field source VnixPickerSearchSources | VnixPickerOrgSources
---@field state unknown?

---@class VnixActivePickers
---@field switch? VnixActivePicker
---@field procs? VnixProcsActivePicker
---@field orgtasks? VnixActivePickers
---@field orgfiles? VnixActivePickers

---@class VnixProcsActivePicker :VnixActivePickerBase
---@field source 'procs'
---@field state snacks.Picker?
