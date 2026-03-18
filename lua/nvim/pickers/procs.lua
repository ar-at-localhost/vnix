local common = require("common")
local t = require("common.time")
local config = require("nvim.config")
local resp = require("nvim.resp")

---@class snacks.picker
---@field procs VnixProcsPickerConfig

---@class VnixProcsPickerConfig :snacks.picker.Config
---@field workspace string?

---@class VnixProcsPickerItem
---@field proc VnixProcRuntime
---@field text string
---@field status string
---@field status_formatted string
---@field preview unknown?
---@field last_updated number
---@field last_updated_formatted string

local icons = {
  [""] = "🔴",
  ready = "🔵",
  running = "🟢",
  stopped = "🟡",
}

---@type table<string, snacks.win.Keys>
local keys = {
  ["<leader>r"] = {
    "run",
    mode = { "n", "v" },
  },
  ["<leader>s"] = {
    "stop",
    mode = { "n", "v" },
  },
}

---@param cb fun(item: VnixProcsPickerItem, picker: SnacksOrgTasksPicker)
---@param kind? 'filter' | 'mutation' | 'done' | 'none'
local function make_action(cb, kind)
  ---@param picker SnacksOrgTasksPicker
  ---@param item VnixProcsPickerItem
  return function(picker, item)
    cb(item, picker)

    if kind == "filter" then
      return picker:find()
    elseif kind == "mutation" then
      return picker:refresh()
    elseif kind == "close" then
      picker:close()
    end
  end
end

---@type VnixProcsPickerConfig
local procs_picker_opts = {
  text = "text",
  preview = "preview",

  ---@param item SnacksOrgTasksPickerItem
  ---@param picker SnacksOrgTasksPicker
  format = function(item, picker)
    return {
      {
        icons[item.status],
      },
      { " " },
      { item.text },
    }
  end,

  ---@param opts VnixProcsPickerConfig
  finder = function(opts)
    local items = {}
    local procs = {}

    if opts.workspace ~= common.vnix_token then
      for i, v in ipairs(config.workspaces) do
        if v.name == opts.workspace then
          procs = v.procs
        end
      end
    end

    procs = procs or config.procs

    for _, v in ipairs(procs) do
      local status_formatted = v.status and v.status:gsub("%l^", string.upper) or ""
      local last_updated = v.last_updated or nil
      local last_updated_formatted = ""
      if last_updated then
        last_updated_formatted = t.iso_timestamp(last_updated)
      end

      table.insert(items, {
        proc = v,
        text = v.title,
        status = v.status,
        status_formatted = status_formatted,
        last_updated = v.last_updated,
        last_updated_formatted = last_updated_formatted,
        preview = {
          ft = "markdown",
          text = string.format(
            [[
### Proc Info
**Title**: %s
**Workspace**: %s
**Status**: %s
**Last updated**: %s
**Preview**:
```
%s
```
]],
            v.title,
            v.workspace,
            status_formatted,
            last_updated_formatted,
            v.preview and (v.scrollback or "") or ""
          ),
        },
      })
    end

    return items
  end,

  actions = {
    run = make_action(function(item)
      local proc = item.proc
      resp.write(resp.create_from_req(
        nil,
        ---@type UIMessageProcsRespData
        {
          subject = proc,
          action = "run",
        }
      ))
    end),
    stop = make_action(function(item)
      local proc = item.proc
      resp.write(resp.create_from_req(
        nil,
        ---@type UIMessageProcsRespData
        {
          subject = proc,
          action = "stop",
        }
      ))
    end),
  },

  confirm = function()
    resp.switch()
  end,

  win = {
    input = {
      keys = keys,
    },
    list = {
      keys = keys,
    },
  },
}

---@type SnacksOrgFilePickerOpts
local M = vim.tbl_extend("force", {
  ft = "org",
  title_format = "both",
  auto_confirm = false,
  auto_close = false,
}, procs_picker_opts)

return M
