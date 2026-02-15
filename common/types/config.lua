---@class VnixConfig Vnix Configuration
---@field workspaces VnixWorkspace[] Workspaces definations

---@class VnixWorkspace
---@field name string Name
---@field tabs VnixTab[] Tab definations
---@field cwd? string Current working directory
---@field env? VnixEnv Environment variables
---@field lazy? boolean Lazy loading
---@field layout? { name: string, opts: unknown }
---@field meta? table<string, unknown>

---@class VnixTab
---@field name string Name
---@field pane VnixPane
---@field cwd? string Current working directory
---@field env? VnixEnv Environment variables
---@field lazy? boolean Lazy loading
---@field meta? table<string, unknown>

---@class VnixPane
---@field name string Name
---@field cwd? string Current working directory
---@field env? VnixEnv Environment variables
---@field args? string[] Command to spawn, start with `:` to apply lazy execution (examples: `{ 'ls', '-l', '-a' }` OR `{ ':', 'ls', '-l', '-a' }`)
---@field size? PaneSizeBase
---@field right? VnixPane
---@field bottom? VnixPane
---@field first_split? 'Right' | 'Bottom'
---@field meta? table<string, unknown>

---@class PaneSizeBase
---@field width? number
---@field height? number

---@alias VnixEnv table<string, string>
