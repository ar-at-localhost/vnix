---@class VNixCommon
---@field VNIX_NVIM_SOCK_PATH string
---@field VNIX_USER_VAR_NAME string
---@field create_resp fun(req: UIMessageReqBase, data: unknown): UIMessageRespBase Create a UI Response
---@field attempt_create_file function(path: string) Attempts to create a new file at the given path.
---@field write_json fun(path: string, tbl: table): string Write Lua table as JSON to file.
---@field read_json fun(path: string): unknown Read Lua table from JSON file.
---@field safe_read_json fun(path: string, fallback: table): table Safely read table, write fallback if don't exists
---@field obj_to_tbl fun(obj: unknown) Convert an object to a table, useful when reading Array data from JSON files

---@class VNixKeybinding
---@field key string
---@field mods? string
---@field description? string
---@field group? string

---@alias VNixKeybindings VNixKeybinding[]
---@alias SpecType 'pane' | 'layout'

---@class PaneRequireds
---@field workspace string name of the workspace
---@field tab string name of the tab
---@field name string name of the pane

---@class PaneOptionals The Pane Specification Object
---@field cwd? string The current working directory
---@field args? table The command to be executed for pane
---@field args_mode? string The command to be executed for pane
---@field right? number The right pane ID
---@field bottom? number The bottom pane ID
---@field left? number The left pane ID
---@field top? number The top pane ID
---@field first? "right" | "bottom" The first split to apply, right or bottom
---@field spec_type? 'pane'
---@field env? table<string, string|number>

---@class PaneSpec: PaneRequireds
---@field cwd? string The current working directory
---@field args? table The command to be executed for pane
---@field args_mode? string The command to be executed for pane
---@field right? number The right pane ID
---@field bottom? number The bottom pane ID
---@field left? number The left pane ID
---@field top? number The top pane ID
---@field first? "right" | "bottom" The first split to apply, right or bottom
---@field spec_type? 'pane'
---@field env? table<string, string|number|nil>
---@field meta? table<string, any>

---@class PaneSize: PaneSizeBase
---@field percent? PaneSizeBase
---@field relative? number

---@class LayoutSpec Workspace Specification Object
---@field layout string The name of the layout to apply
---@field spec_type? 'layout'
---@field opts? table Options and override (based on particular layout)

---@class PaneState: PaneSpec
---@field _workspace_id string
---@field _tab_id number
---@field _pane_id number
---@field _tab_index? number
---@field _wez_pane_index? number
---@field focus_workspace? boolean
---@field focus_tab? boolean
---@field focused? boolean
---@field tt? number Time tracked so far
---@field ttb? number Time tracking break so far
---@field ttd? string Time tracking date
---@field size PaneSize
---@field lazy? string

---@alias StateSpec PaneSpec | LayoutSpec The original user specified workspaces
---@alias StateSpecs StateSpec[]
---@alias State PaneState[] The runtime state

---@class VnixActivity
---@field active_pane? VnixPaneState
---@field focus VnixFocus

---@class VNixNvimOpts
---@field vnix_dir string
---
---@class VNixNvimState
---@field vnix_dir string vnix directory path
---@field _ns integer unknown
---@field timesheet string timesheet file name
---@field state VnixStateFlat Vnix panes state
---@field return_to number where to return (last pane idx)
---@field dev_workspaces table<string, { cwd: string, idx: number }>
---@field pad_half string
---@field pad string

---@class PanesWithInfo
---@field index number
---@field is_active boolean
---@field is_zoomed boolean
---@field pane Pane

---@class GLOBAL: userdata
---@field vnix VNixGlobal

---@class Wezterm
---@diagnostic disable-next-line: duplicate-doc-field
---@field GLOBAL GLOBAL
