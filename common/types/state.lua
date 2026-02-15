
---@class VnixWorkspaceState: VnixWorkspace
---@field id string
---@field tabs VnixTabState[]

---@class VnixTabState: VnixTab
---@field id number
---@field idx number
---@field pane VnixPaneState

---@class VnixPaneState: VnixPane
---@field right? VnixPaneState
---@field bottom? VnixPaneState
---@field left? VnixPaneState
---@field top? VnixPaneState
---@field id number
---@field idx number
---@field workspace string
---@field tab string
---@field tab_id number

---@alias VnixFocus table<string, VnixPaneState?>

---@class VnixStateFlatEntry
---@field pane_id number
---@field pane_idx number
---@field pane_name string
---@field tab_id number
---@field tab_idx number
---@field tab_name string
---@field workspace string
---@field cwd? string
---@field meta? table<string, unknown>
---@alias VnixStateFlat VnixStateFlatEntry[]
