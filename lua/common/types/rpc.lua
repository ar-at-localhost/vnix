---@generic UIMessageData

---@alias UIMessageType 'create' | 'debug' | 'inspect' | 'launch' | 'rename' | 'persist' | 'switch' | 'status' | 'org' | 'procs'

---@class UIMessageReqBase<UIMessageData>
---@field id number
---@field workspace string
---@field return_to number
---@field timestamp? string
---@field type UIMessageType
---@field data `UIMessageData`

---@class UIMessageRespBase<T>: UIMessageReqBase
---@field data `T`

--------------------------------------------------------------------------------
---@class UIMessageCreateReq :UIMessageReqBase
---@field type 'create'
---@field data? 'workspace' | 'tab'

---@class UIMessageCreateResp :UIMessageRespBase
---@field type 'create'
---@field data UIMessageCreateRespData

---@alias UIMessageCreateRespData UIMessageCreateWorkspaceRespData | UIMessageCreateTabRespData

---@class UIMessageCreateWorkspaceRespData
---@field type 'workspace'
---@field spec VnixWorkspace

---@class UIMessageCreateTabRespData
---@field type 'tab'
---@field spec VnixTab

--------------------------------------------------------------------------------
---@alias RenameTarget 'workspace' | 'tab' | 'pane' | 'all'

---@class UIMessageRenameReq :UIMessageReqBase
---@field type 'rename'
---@field data? RenameTarget

---@class UIMessageRenameResp :UIMessageRespBase
---@field type 'rename'
---@field data UIMessageRenameRespData
---@alias UIMessageRenameRespData { kind: RenameTarget, name: string }

--------------------------------------------------------------------------------
---@class UIMessageDebugReq :UIMessageReqBase
---@field type 'debug'
---@field pid number
---@field data UIMessageDebugReqReplyData?

---@class UIMessageDebugReqReplyData
---@field id number
---@field ok boolean
---@field result string

---@class UIMessageDebugResp :UIMessageRespBase
---@field type 'debug'
---@field data UIMessageDebugRespData

---@alias UIMessageDebugRespData UIMessageDebugRunRespData

---@class UIMessageDebugRunRespData
---@field type 'run'
---@field lua string

-------------------------------------------------------------------------------k
---@class LuanchMessageReq :UIMessageReqBase
---@field type 'launch'
---@field keys VNixKeybindings

---@class LuanchMessageResp :UIMessageRespBase
---@field type 'launch'
---@field ok? boolean If launch is success or any error?
---@field err? string Error if any

--------------------------------------------------------------------------------
---@class UIMessageSwitchReq :UIMessageReqBase
---@field type 'switch'
---@field data VnixPaneRecency

---@class UIMessageSwitchResp :UIMessageRespBase
---@field type 'switch'
---@field data? UIMessageSWitchRespData

---@class UIMessageSWitchRespData
---@field workspace string
---@field tab string
---@field pane string
---@field ctx? 'pane' | 'tab' | 'workspace'

---@class UIMessagePersistReq :UIMessageReqBase
---@field type 'persist'
---@field data string

---@class UIMessageSaveResp :UIMessageRespBase
---@field type 'switch'
---@field data? boolean

---@class UIMessageLaunchReq :UIMessageReqBase
---@field type 'launch'
---@field data nil

--------------------------------------------------------------------------------
---@class UIMessageOrgReq :UIMessageReqBase
---@field type 'org'
---@field data 'files' | 'tasks'

---@class UIMessageOrgResp :UIMessageRespBase
---@field data UIMessageOrgRespData

---@class UIMessageOrgRespData
---@field sync_clock? boolean

--------------------------------------------------------------------------------
---@class UIMessageProcsReq :UIMessageReqBase
---@field type 'procs'
---@field data VnixProcRuntime[]

---@class UIMessageProcsResp :UIMessageRespBase
---@field data UIMessageProcsRespData

---@class UIMessageProcsRespData
---@field action 'close' | 'run' | 'stop'
---@field subject? VnixProcRuntime
