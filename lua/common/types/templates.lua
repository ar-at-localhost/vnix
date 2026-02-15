--- @alias VnixWorkspaceLayoutName 'scratch' | 'dev'

--- @class VnixWorkspaceLayout
--- @field name VnixWorkspaceLayoutName
--- @field desc string
--- @field form VnixFormSpec?
---
---@class VnixFormSpec
---@field title? string
---@field desc? string
---@field fields VnixNvimFormField[]
---@field keys? VnixFormKeys
---@field help? VnixFormHelp
---@alias VnixFormHelp VnixVirtLine[]
---@alias VnixVirtLine {[1]: VirtLineText, [2]: VirtLineHighlight}[]
---@alias VirtLineText string
---@alias VirtLineHighlight string

---@class VnixFormKey: snacks.win.Keys
---@field [2] fun(form: VnixForm, win: snacks.win)
---@alias VnixFormKeys table<string, VnixFormKey>

---@class VnixNvimFormField
---@field key string
---@field title? string
---@field desc? string
---@field default string?
---@field required boolean?
---@field do_not_render boolean?
---@field value? string

---@class VnixNvimFormSubmission :VnixFormSpec
---@field fields VnixNvimFormFieldSubmission[]

---@class VnixNvimFormFieldSubmission: VnixNvimFormField
---@field result string

---@class VnixTemplateBase
---@field type 'workspace' | 'tab'
---@field name string
---@field desc string
---@field id string
---@field form VnixFormSpec?

---@class VnixTemplateOptsBase
---@field name string Name
---@field cwd? string Current working directory

---@class VnixWorkspaceTemplateOptsBase: VnixTemplateOptsBase
---@class VnixTabTemplateOptsBase: VnixTemplateOptsBase

---@class VnixWorkspaceTemplate: VnixTemplateBase
---@field type 'workspace'
---@field apply fun(opts: VnixWorkspaceTemplateOptsBase, base: VnixWorkspace?): VnixWorkspace
---
---@class VnixTabTemplate: VnixTemplateBase
---@field type 'tab'
---@field apply fun(opts: VnixTabTemplateOptsBase, base: VnixTab?): VnixTab

---@alias VnixTemplate VnixWorkspaceTemplate | VnixTabTemplate
