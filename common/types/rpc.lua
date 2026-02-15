---@generic UIMessageData

---@alias UIMessageType 'create' | 'debug' | 'inspect' | 'launch' | 'debug' | 'save' | 'switch' | 'timesheet'

---@class UIMessageReqBase<UIMessageData>
---@field id number
---@field return_to number
---@field timestamp? string
---@field type UIMessageType
---@field data `UIMessageData`

---@class UIMessageRespBase<T>: UIMessageReqBase
---@field data `T`

--------------------------------------------------------------------------------
---@class UIMessageCreateReq :UIMessageReqBase
---@field type 'create'
---@field data nil

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
