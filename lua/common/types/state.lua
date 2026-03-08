
---@class VnixWorkspaceState: VnixWorkspace
---@field id string
---@field tabs VnixTabState[]

---@class VnixTabState: VnixTab
---@field id number wezterm id
---@field idx number 0 based index
---@field pane VnixPaneState root pane

---@class VnixPaneState: VnixPane
---@field right? VnixPaneState
---@field bottom? VnixPaneState
---@field left? VnixPaneState
---@field top? VnixPaneState
---@field id number wezterm id
---@field idx number 0 based index
---@field workspace string name of the workspace
---@field tab string name of the tab
---@field tab_id number wezterm id
---@field tab_idx number tab index (0-based)

---@alias VnixFocus table<string, VnixPaneState?>

---@class VnixPaneFlat
---@field pane_id number
---@field pane_idx number
---@field pane_name string
---@field tab_id number
---@field tab_idx number
---@field tab_name string
---@field workspace string
---@field cwd? string
---@field meta? table<string, unknown>
---@alias VnixPanesFlat VnixPaneFlat[]
