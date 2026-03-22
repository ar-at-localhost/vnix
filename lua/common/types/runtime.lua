---@class VnixWorkspaceRuntime: VnixWorkspace
---@field id string
---@field tabs VnixTabRuntime[]
---@field procs VnixProcRuntime[]
---@field lazy_loaded boolean?

---@class VnixTabRuntime: VnixTab
---@field id number wezterm id
---@field idx number 0 based index
---@field pane VnixPaneRuntime root pane
---@field lazy_loaded boolean?

---@class VnixPaneRuntime: VnixPane
---@field right? VnixPaneRuntime
---@field bottom? VnixPaneRuntime
---@field left? VnixPaneRuntime
---@field top? VnixPaneRuntime
---@field id number wezterm id
---@field idx number 0 based index
---@field workspace string name of the workspace
---@field tab string name of the tab
---@field tab_id number wezterm id
---@field tab_idx number tab index (0-based)

---@class VnixProcRuntime :VnixProc
---@field id string
---@field workspace string
---@field tab_id integer
---@field scrollback string?
---@field status 'ready' | 'running' | 'stopped'
---@field last_updated integer

---@alias VnixFocus table<string, VnixPaneRuntime?>

---@class VnixPaneFlat
---@field pane_id number
---@field pane_idx number
---@field pane_name string
---@field tab_id number
---@field tab_idx number
---@field tab_name string
---@field workspace string
---@field recency integer
---@field cwd? string
---@field meta? table<string, unknown>
---@field lazy_status? '' | 'workspace' | 'tab' | 'loaded'
---@alias VnixPanesFlat VnixPaneFlat[]
