--- @alias VnixWorkspaceLayoutName 'scratch' | 'dev'

--- @class VnixWorkspaceLayout
--- @field name VnixWorkspaceLayoutName
--- @field desc string
--- @field form VnixNvimForm?
---
---@class VnixNvimForm
---@field title? string
---@field desc? string
---@field fields VnixNvimFormField[]

---@class VnixNvimFormField
---@field key string
---@field title? string
---@field desc? string
---@field default string?
---@field required boolean?

---@class VnixNvimFormSubmission :VnixNvimForm
---@field fields VnixNvimFormFieldSubmission[]

---@class VnixNvimFormFieldSubmission: VnixNvimFormField
---@field result string

---@class VnixTemplateBase
---@field type 'workspace' | 'tab'
---@field name string
---@field desc string
---@field id string
---@field form VnixNvimForm?

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
