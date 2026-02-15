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
