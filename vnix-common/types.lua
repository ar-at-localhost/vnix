---@class VNixCommon
---@field VNIX_NVIM_SOCK_PATH string
---@field VNIX_USER_VAR_NAME string
---@field create_resp fun(req: UIMessageReqBase, data: unknown): UIMessageRespBase Create a UI Response
---@field attempt_create_file function(path: string) Attempts to create a new file at the given path.
---@field write_json fun(path: string, tbl: table): string Write Lua table as JSON to file.
---@field read_json fun(path: string): unknown Read Lua table from JSON file.
---@field safe_read_json fun(path: string, fallback: table): table Safely read table, write fallback if don't exists
---@field obj_to_tbl fun(obj: unknown) Convert an object to a table, useful when reading Array data from JSON files

---@class VNixConfig
---@field keys unknown # TODO: add key's type
---@field vnix_dir? string Where to look for and store Vnix files? Default: ~/.vnix
---@field workspaces_file? string Path to readonly workspaces defination file. Default: nil
---@field status_update_interval? number
---@field debug? boolean Enable debug mode

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
---@field extras? table<string, any>

---@class PaneSizeBase
---@field width? number
---@field height? number

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

---@generic UIMessageData

---@alias UIMessageReqType 'launch' | 'inspect' | 'switch' |'create' | 'save' | 'timesheet'

---@class UIMessageReqBase<UIMessageData>
---@field id number
---@field return_to number
---@field timestamp? string
---@field type UIMessageReqType
---@field data `UIMessageData`

---@class UIMessageRespBase<T>: UIMessageReqBase
---@field data `T`

---@class LuanchMessageReq :UIMessageReqBase
---@field type 'launch'
---@field keys VNixKeybindings

---@class LuanchMessageResp :UIMessageRespBase
---@field type 'launch'
---@field ok? boolean If launch is success or any error?
---@field err? string Error if any

---@class UIMessageSwitchReq :UIMessageReqBase
---@field type 'switch'
---@field data nil

---@class UIMessageSwitchResp :UIMessageRespBase
---@field type 'switch'
---@field data? number Where to switch to? `nil`: no where, 0: last active, +ve int: to given, -ve int: ignore

---@class UIMessageSaveReq :UIMessageReqBase
---@field type 'save'
---@field data { path: string, data: unknown }[]

---@class UIMessageSaveResp :UIMessageRespBase
---@field type 'switch'
---@field data? boolean

---@class UIMessageLaunchReq :UIMessageReqBase
---@field type 'launch'
---@field data nil

---@class UIMessageTTReq :UIMessageReqBase
---@field type 'timesheet'
---@field data? 'on' | 'off' | 'menu' | 'sheet'

---@alias UIMessageTTRespData 'start' | 'stop' | 'reset'
---@class UIMessageTTResp :UIMessageReqBase
---@field type 'timesheet'
---@field data UIMessageTTRespData

---@class VnixActivity
---@field file string
---@field cp_id number
---@field tt? boolean Time tracker status (ON / OFF)
---@field tts number
---@field tt_lock? boolean Time tracker status (ON / OFF)
---@field total_break_today number
---@field total_non_break_today number
---@field total_time_today? number

---@class VNixGlobal
---@field vnix_dir? string
---@field is_ready? boolean
---@field user_home string Home directory of the user
---@field home string Directory of the VNix
---@field shell string
---@field state_file string
---@field workspaces_file string
---@field log_count number
---@field flushed_logs_count number
---@field logs table
---@field log_file string
---@field state? table
---@field orignal_workspace? string
---@field keybindings? VNixKeybindings
---@field use_nix? boolean
---@field nix_path? string
---@field current_pane_index? number
---@field activity VnixActivity
---@field activity_file string
---@field timesheet? table
---@field timesheet_file? string
---@field no_nvim_ui? boolean
---@field ui_running? boolean
---@field ui_next_req number
---@field debug? boolean

---@class VNixNvimOpts
---@field vnix_dir string
---
---@class VNixNvimState
---@field vnix_dir string vnix directory path
---@field timesheet string timesheet file name
---@field activity VnixActivity Vnix activity
---@field state PaneState[] Vnix panes state
---@field return_to number where to return (last pane idx)
---@field dev_workspaces table<string, { cwd: string, idx: number }>

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
