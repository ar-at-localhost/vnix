---@class VNixKeybindingInfo
---@field key string
---@field mods? string
---@field description? string
---@field group? string

---@class VNixKeybinding :VNixKeybindingInfo
---@field action Action

---@alias VNixKeybindings table<string, VNixKeybinding>
