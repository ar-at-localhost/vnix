local config = require("nvim.config")
local orgmode = require("orgmode")
local str = require("common.str")
local org = require("nvim.org")
local helpers = require("nvim.org.helpers")

---@class snacks.picker
---@field tasks snacks.Picker

---@class VnixOrgTasksActivePicker
---@field source 'tasks'
---@field state VnixOrgTasksPickerState

---@class VnixOrgTasksPickerState
---@field workspace 'all' | string
---@field level integer
---@field keywords table<string, string>
---@field node? OrgHeadline
---@field sort? 'deadline' | 'priority'

---@class VnixOrgTasksPickerItem
---@field node OrgHeadline
---@field file string
---@field text string
---@field tags string
---@field status string
---@field statusl string
---@field level integer
---@field priority integer
---@field deadline_unix integer
---@field preview snacks.picker.preview

local known_sorts = config.org.sorts

config.pickers.tasks = {
  source = "tasks",
  state = {
    keywords = str.pad_items(config.org.keywords),
    workspace = "all",
    level = 1,
    sort = "deadline",
  },
}

local state = config.pickers.tasks.state

---@type table<string, snacks.win.Keys>
local keys = {
  [">"] = {
    "depth_in",
    mode = { "i", "n" },
  },
  ["<"] = {
    "depth_out",
    mode = { "i", "n" },
  },
  ["="] = {
    "depth_reset",
    mode = { "i", "n" },
  },
  ["<a-s>"] = {
    "cycle_sort",
    mode = { "i", "n", "v" },
  },
  ["<leader>+"] = {
    "priority_up",
    mode = { "n", "v" },
    desc = "Increase Priority",
  },
  ["<leader>-"] = {
    "priority_down",
    mode = { "n", "v" },
    desc = "Decrease Priority",
  },
  ["<leader>t"] = {
    "status_todo",
    mode = { "n", "v" },
    desc = "Status: TODO",
  },
  ["<leader>p"] = {
    "status_prog",
    mode = { "n", "v" },
    desc = "Status: PROG (IN PROGRESS)",
  },
  ["<leader>d"] = {
    "status_done",
    mode = { "n", "v" },
    desc = "Status: DONE",
  },
  ["<leader>c"] = {
    "status_closed",
    mode = { "n", "v" },
    desc = "Status: CLOSED",
  },
  ["<leader>C"] = {
    "toggle_clock",
    mode = { "n", "v" },
    desc = "Toggle clock",
  },
}

---@param cb fun(item: VnixOrgTasksPickerItem)
---@param kind? 'filter' | 'mutation'
local function make_action(cb, kind)
  ---@param picker snacks.Picker
  ---@param item VnixOrgTasksPickerItem
  return function(picker, item)
    cb(item)

    if kind == "filter" then
      return picker:find()
    elseif kind == "mutation" then
      return picker:refresh()
    end
  end
end

---@param status 'TODO' | 'PROG' | 'DONE' | 'CLOSED'
local function make_status_action(status)
  return make_action(function(item)
    local existing_status = item.node:get_todo()

    if existing_status and existing_status == status then
      Snacks.notify(string.format("Task is already in %s status.", status), {
        title = "Task status",
      })

      return
    end

    local headline_api = helpers.resolve_headline_api(item.node)
    if headline_api then
      item.node:set_todo(status)
    end
  end, "mutation")
end

---@type snacks.picker.Config
local picker = {
  auto_confirm = false,
  auto_close = false,
  preview = "preview",

  ---@param item VnixOrgTasksPickerItem
  format = function(item)
    return {
      {
        config.pickers.tasks.state.keywords[item.status and item.status or ""],
        string.format("@org.keyword%s%s", item.statusl and "." or "", item.statusl or ""),
      },
      { " " },
      { item.text, string.format("@org.headline.level%d", item.level) },
      { " " },
      { item.tags, "@org.tag" },
    }
  end,

  ---@return VnixOrgTasksPickerItem[]
  finder = function()
    orgmode:reload()
    local files = orgmode.files
    ---@type VnixOrgTasksPickerItem[]
    local items = {}

    for _, f in pairs(files.files) do
      local headlines = f:get_headlines()

      for _, h in ipairs(headlines) do
        local status = h:get_todo() or ""
        local deadline = h:get_deadline_date()
        local priority = h:get_priority()

        ---@type VnixOrgTasksPickerItem
        local item = {
          node = h,
          file = f.filename,
          text = h:get_title(),
          status = status,
          statusl = status:lower(),
          level = h:get_level(),
          tags = table.concat(h:get_tags(), " "),
          priority = helpers.priority_to_integer(priority),
          deadline = deadline,
          deadline_unix = (deadline and deadline.timestamp) or math.huge,
          ---@diagnostic disable-next-line: assign-type-mismatch
          preview = {
            ft = "org",
            text = table.concat(h:get_lines(), "\n"),
          },
        }

        table.insert(items, item)
      end
    end

    return items
  end,

  ---@param item VnixOrgTasksPickerItem
  transform = function(item)
    local parent = item.node:get_parent_headline()
    return (state.node and state.node == parent or (item.level == state.level))
  end,

  ---@param a VnixOrgTasksPickerItem
  ---@param b VnixOrgTasksPickerItem
  sort = function(a, b)
    if state.sort == "priority" then
      return a.priority > b.priority
    elseif state.sort == "deadline" then
      return a.deadline_unix < b.deadline_unix
    end

    return true
  end,

  win = {
    input = {
      keys = vim.tbl_extend("force", keys, {}),
    },
    list = {
      keys = vim.tbl_extend("force", keys, {}),
    },
  },

  actions = {
    depth_in = make_action(function(item)
      local childs = item.node:get_child_headlines()
      if #childs <= 0 then
        vim.notify("Task has no sub-tasks!", "warn")
        return
      end

      state.node = item.node
      state.level = state.level + 1
    end, "filter"),

    depth_out = make_action(function(item)
      state.node = item.node:get_parent_headline()

      if state.level >= 2 then
        state.level = state.level - 1
      end
    end, "filter"),

    depth_reset = make_action(function()
      state.node = nil
      state.level = 1
    end, "filter"),

    cycle_sort = make_action(function()
      local idx = 1

      for i, v in ipairs(known_sorts) do
        if v == state.sort then
          idx = i
          break
        end
      end

      idx = (idx % #known_sorts) + 1
      state.sort = known_sorts[idx]
      -- FIXME: It is not a filter
    end, "filter"),

    priority_up = make_action(function(item)
      local priority = item.node:get_priority()
      if priority and priority == "A" then
        Snacks.notify("Task is already at priority A.", {
          title = "Priority [A]",
        })
        return
      end

      local headline_api = helpers.resolve_headline_api(item.node)
      if headline_api then
        headline_api:priority_up()
      end
    end, "mutation"),

    priority_down = make_action(function(item)
      local priority = item.node:get_priority()

      if priority and priority == "C" or priority == "" then
        Snacks.notify(
          string.format(
            "Task is already at%s priority%s.",
            priority == "" and " lowest" or "",
            priority ~= "" and (string.format("Priority [%s]", priority)) or ""
          ),
          {
            title = priority == "" and "Priority Down" or "Priority " .. priority,
          }
        )
        return
      end

      local headline_api = helpers.resolve_headline_api(item.node)
      if headline_api then
        headline_api:priority_down()
      end
    end, "mutation"),

    status_todo = make_status_action("TODO"),
    status_prog = make_status_action("PROG"),
    status_done = make_status_action("DONE"),
    status_closed = make_status_action("CLOSED"),

    toggle_clock = make_action(function(item)
      local headline_api = helpers.resolve_headline_api(item.node)

      if headline_api then
        headline_api:toggle_clock()
        --- TODO: Refresh picker (especially preview)
      end
    end, "mutation"),
  },
}

---@type snacks.picker.Config
local M = vim.tbl_extend("force", {}, picker)

return M
