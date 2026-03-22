local config = require("nvim.config")
local resp = require("nvim.resp")
local tbl = require("common.tbl")
local str = require("common.str")

---@class snacks.picker
---@field switch snacks.Picker

---@class VnixSwitchPickerConfig :snacks.picker.Config
---@field kind 'workspace' | 'tab' | 'pane'
---@field recency VnixPaneRecency

---@class VnixSwitchPickerRuntime :snacks.Picker
---@field opts VnixSwitchPickerConfig

---@class VnixSwitchPickerItem : VnixPaneFlat
---@field ref VnixPaneFlat
---@field text string
---@field preview { ft: string, text: string }

local lazy_statuses = {
  [""] = "🔵",
  ["workspace"] = "🟥",
  ["tab"] = "🔴",
  ["lazy"] = "🟢",
  ["lazy_loaded"] = "🟡",
}

---@type snacks.picker.Config
local switch = {
  format = "text",
  auto_confirm = false,
  auto_close = false,
  preview = "preview",
  layout = "ivy",

  ---@param opts VnixSwitchPickerConfig
  finder = function(opts)
    opts.recency = opts.recency or {}
    opts.kind = opts.kind or "pane"
    local items = {}
    local seen = {}

    for _, v in pairs(config.panes) do
      local p = tbl.deep_copy(v)
      local tab_key = p.workspace .. "." .. p.tab_name

      ---@cast p VnixSwitchPickerItem

      if
        opts.kind == "pane"
        or ((opts.kind == "workspace") and (not seen[p.workspace] or seen[p.workspace] > p.recency))
        or ((opts.kind == "tab") and (not seen[tab_key] or seen[tab_key] > p.recency))
      then
        table.insert(items, p)
        seen[p.workspace] = p.recency
        seen[tab_key] = p.recency
      end

      p.ref = p

      p.text = string.format(
        "%s %s > %s > %s",
        lazy_statuses[p.lazy_status],
        str.pad(p.workspace, 20),
        str.pad(p.tab_name, 20),
        str.pad(p.pane_name, 20)
      )

      p.preview = {
        ft = "markdown",
        text = string.format(
          [[# Pane Info

**Workspace**: %s
**Tab**: %s
**Pane**: %s
]],
          p.workspace,
          p.tab_name,
          p.pane_name
        ),
      }
    end

    return items
  end,

  ---@param self VnixSwitchPickerRuntime
  ---@param item VnixSwitchPickerItem
  confirm = function(self, item)
    local kind = self.opts.kind

    ---@type UIMessageSWitchRespData
    local data = {
      workspace = item.ref.workspace,
      tab = item.ref.tab_name,
      pane = item.ref.pane_name,
      ctx = kind,
    }

    resp.write(resp.create_from_req(nil, data))
    self:close()
  end,

  win = {
    input = {
      keys = {
        -- selene: allow(mixed_table)
        ["<leader>w"] = {
          "workspaces",
          mode = { "n", "v" },
        },
        -- selene: allow(mixed_table)
        ["<leader>t"] = {
          "tabs",
          mode = { "n", "v" },
        },
        -- selene: allow(mixed_table)
        ["<leader>p"] = {
          "panes",
          mode = { "n", "v" },
        },
      },
    },
  },

  actions = {
    ---@param self VnixSwitchPickerRuntime
    workspaces = function(self)
      if self.opts.kind == "workspaces" then
        return
      end

      self.opts.kind = "workspace"
      self:find()
    end,
    ---@param self VnixSwitchPickerRuntime
    tabs = function(self)
      if self.opts.kind == "tab" then
        return
      end

      self.opts.kind = "tab"
      self:find()
    end,
    ---@param self VnixSwitchPickerRuntime
    panes = function(self)
      if self.opts.kind == "pane" then
        return
      end

      self.opts.kind = "pane"
      self:find()
    end,
  },
}

return switch
