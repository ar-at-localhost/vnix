local config = require("nvim.config")
local orgmode = require("orgmode")
local orgmode_config = require("orgmode.config")
local api = require("orgmode.api")
local helpers = require("nvim.org.helpers")
local tbl = require("common.tbl")

---@class snacks.picker
---@field orgtasks SnacksOrgTasksPicker

---@class SnacksOrgTasksPicker: snacks.Picker
---@field opts SnacksOrgTasksPickerConfig

---@class SnacksOrgTasksPickerConfig: snacks.picker.Config
---@field dirs? string[] directories to search
---@field sort SnacksOrgTasksPickerSort?
---@field level integer
---@field file string?
---@field keywords string[]?
---@field _keywords table<string, string>?
---@field node? OrgHeadline
---@field actions SnacksOrgTasksPickerActionsSpecs
---@field hooks? { after?: table<SnacksOrgTasksPickerAction, fun(item: SnacksOrgTasksPickerItem, picker: snacks.Picker, action?: SnacksOrgTasksPickerAction)> }

---@class SnacksOrgTasksPickerFindarCtx :snacks.picker.finder.ctx
---@field _opts SnacksOrgTasksPickerConfig

---@alias SnacksOrgTasksPickerActionsSpecs table<SnacksOrgTasksPickerAction, snacks.picker.Action.spec>
---@alias SnacksOrgTasksPickerAction 'priority_up' | 'priority_down' | 'toggle_clock' | 'refile' | 'refile_to_headline'

---@class SnacksOrgTasksPickerFilter
---@field filter fun(item: SnacksOrgTasksPickerItem, filter: SnacksOrgTasksPickerFilterOpts):boolean?

---@class SnacksOrgTasksPickerSort
---@field fields SnacksOrgTasksPickerSortFields

---@class SnacksOrgTasksPickerSortFields
---@field priority snacks.picker.sort.Field
---@field deadline snacks.picker.sort.Field

---@class SnacksOrgTasksPickerFilterOpts
---@field level integer
---@field file string?
---@field keywords table<string, string>?
---@field node? OrgHeadline

---@class SnacksOrgTasksPickerItem
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
  ["<leader>r"] = {
    "refile",
    mode = { "n", "v" },
    desc = "Refile",
  },
  ["<leader>R"] = {
    "refile_to_headline",
    mode = { "n", "v" },
    desc = "Refile to headline",
  },
  ["<leader>C"] = {
    "toggle_clock",
    mode = { "n", "v" },
    desc = "Toggle clock",
  },
  ["<leader>x"] = {
    "cancel_active_clock",
    mode = { "n", "v" },
    desc = "Cancel active clock",
  },
}

---@param cb fun(item: SnacksOrgTasksPickerItem, picker: SnacksOrgTasksPicker)
---@param kind? 'filter' | 'mutation' | 'done'
local function make_action(cb, kind)
  ---@param picker SnacksOrgTasksPicker
  ---@param item SnacksOrgTasksPickerItem
  return function(picker, item)
    cb(item, picker)

    if kind == "filter" then
      return picker:find()
    elseif kind == "mutation" then
      return picker:refresh()
    elseif kind == "done" then
      picker:close()
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

---@type SnacksOrgTasksPickerConfig
local picker = {
  level = 1,
  auto_confirm = false,
  auto_close = false,
  preview = "preview",

  ---@param item SnacksOrgTasksPickerItem
  ---@param picker SnacksOrgTasksPicker
  format = function(item, picker)
    return {
      {
        picker.opts._keywords[item.statusl and item.statusl] or "----",
        string.format("@org.keyword%s%s", item.statusl and "." or "", item.statusl or ""),
      },
      { " " },
      { item.text, string.format("@org.headline.level%d", item.level) },
      { " " },
      { item.tags, "@org.tag" },
    }
  end,

  ---@param opts SnacksOrgTasksPickerConfig
  ---@return SnacksOrgTasksPickerItem[]
  finder = function(opts)
    orgmode.files:load_sync(true)

    opts._keywords = opts._keywords
      or tbl.map(
        tbl.filter(orgmode_config.org_todo_keywords or {}, function(item)
          return item ~= "|"
        end),
        ---@param item string
        function(item)
          return item:lower(), item:upper()
        end
      )

    local files = orgmode.files
    ---@type SnacksOrgTasksPickerItem[]
    local items = {}

    for _, f in pairs(files.files) do
      local headlines = f:get_headlines()

      for _, h in ipairs(headlines) do
        local status = h:get_todo() or ""
        local deadline = h:get_deadline_date()
        local priority = h:get_priority()

        ---@type SnacksOrgTasksPickerItem
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

    if opts.dirs then
      for _, dir in pairs(opts.dirs) do
        items = vim.tbl_filter(function(item)
          return vim.startswith(item.file, vim.fs.normalize(dir))
        end, items)
      end
    end

    return items
  end,

  ---@param item SnacksOrgTasksPickerItem
  ---@param ctx SnacksOrgTasksPickerFindarCtx
  transform = function(item, ctx)
    local opts = ctx.picker.opts --[[@cast opts SnacksOrgTasksPickerConfig]]
    local parent = item.node:get_parent_headline()
    local o = opts or {
      level = 1,
    }

    return (
      (item.level == o.level)
      and (not o.keywords or (o.keywords[item.statusl] and true))
      and (not o.node or parent and o.node.file == parent.file and o.node.headline == parent.headline)
      and (not o.file or item.file == o.file)
    )
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
    depth_in = make_action(function(item, picker)
      local opts = picker.opts

      local childs = item.node:get_child_headlines()
      if #childs <= 0 then
        vim.notify("Task has no sub-tasks!", "warn")
        return
      end

      opts.node = item.node
      opts.level = opts.level + 1
    end, "filter"),

    depth_out = make_action(function(_, picker)
      local opts = picker.opts
      opts.node = opts.node and opts.node:get_parent_headline()
      opts.level = opts.level - 1

      if opts.level <= 1 then
        opts.level = 1
        opts.node = nil
      end
    end, "filter"),

    depth_reset = make_action(function(_, picker)
      local opts = picker.opts
      opts.node = nil
      opts.level = 1
    end, "filter"),

    cycle_sort = make_action(function(_, picker)
      local state = picker.opts
      local idx = 1

      for i, v in ipairs(known_sorts) do
        if v == state.sort then
          idx = i
          break
        end
      end

      idx = (idx % #known_sorts) + 1
      state.sort = {
        fields = {
          priority = {
            name = "priority",
          },
          deadline = {
            name = "priority",
          },
        },
      }
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

    toggle_clock = make_action(function(item, picker)
      local headline_api = helpers.resolve_headline_api(item.node)

      if headline_api then
        headline_api
          :is_clocked_in()
          :next(function(clocked_in)
            if clocked_in then
              return headline_api:clock_out()
            end

            return headline_api:clock_in()
          end)
          :next(function()
            pcall(function()
              picker.opts.hooks.after.toggle_clock(item, picker, "toggle_clock")
            end)
          end)
          :catch(function(err)
            vim.notify(vim.inspect(err), vim.log.levels.WARN)
          end)
      end
    end),

    cancel_active_clock = make_action(function(item)
      local headline_api = helpers.resolve_headline_api(item.node)

      if headline_api then
        headline_api:cancel_active_clock()
      end
    end, "mutation"),

    refile = make_action(function(item, this_picker)
      local opts = this_picker.opts

      Snacks.picker.orgfiles({
        dirs = opts.dirs,
        confirm = function(picker, file_item)
          local headline_api = helpers.resolve_headline_api(item.node)
          local file_api = helpers.resolve_file_api(file_item.file)

          if headline_api and file_api then
            api
              .refile({
                source = headline_api,
                destination = file_api,
              })
              :next(function()
                picker:close()
                pcall(function()
                  this_picker.opts.hooks.after.refile(item, this_picker, "refile")
                end)
              end)
          end
        end,
      })
    end, "done"),

    ---@param item SnacksOrgTasksPickerItem
    refile_to_headline = make_action(function(item, this_picker)
      local opts = this_picker.opts

      Snacks.picker.orgfiles({
        confirm = function(_, file_item)
          Snacks.picker.orgtasks({
            dirs = opts.dirs,
            file = file_item.file,
            level = 1,
            confirm = function(picker, dest_item)
              local source_headline_api = helpers.resolve_headline_api(item.node)
              local des_headline_api = helpers.resolve_headline_api(dest_item.node)

              if source_headline_api and des_headline_api then
                api
                  .refile({
                    source = source_headline_api,
                    destination = des_headline_api,
                  })
                  :next(function()
                    pcall(function()
                      picker:close()

                      pcall(function()
                        this_picker.opts.hooks.after.refile(item, this_picker, "refile_to_headline")
                      end)
                    end)
                  end)
              end
            end,
          })
        end,
      })
    end, "done"),
  },
}

---@type snacks.picker.Config
local M = vim.tbl_extend("force", {
  keywords = vim.tbl_map(
    ---@param t OrgTodoKeyword
    function(t)
      return t.keyword
    end,

    orgmode_config.todo_keywords and orgmode_config.todo_keywords:all() or {}
  ),
}, picker)

return M
