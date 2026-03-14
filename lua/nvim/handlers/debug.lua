local resp = require("nvim.resp")
local config = require("nvim.config")

---@class VnixVNimDebugMod
---@field _debug_wezterm fun(req: UIMessageDebugReq)
---@field _debug_nvim fun()
---@field _show_rpc fun()
local M = {} ---@type VnixVNimDebugMod

function M.close()
  resp.switch()
end

function M._debug_wezterm(req)
  local editor ---@type snacks.win
  local output ---@type snacks.win

  local cwd = vim.fn.getenv("VNIX_PLUGIN_DIR")
  local file = string.format("%s/.nvim/wezterm.lua", cwd)

  local log_file = string.format(
    "%s/wezterm/wezterm-gui-log-%d.txt",
    (vim.fn.getenv("XDG_RUNTIME_DIR") or ""),
    req.pid
  )

  local output_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[output_buf].swapfile = false
  vim.bo[output_buf].bufhidden = "wipe"

  local function reload_log()
    if not vim.api.nvim_buf_is_valid(output_buf) then
      return
    end
    local ok, lines = pcall(vim.fn.readfile, log_file)
    if not ok then
      return
    end
    vim.bo[output_buf].modifiable = true
    vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, lines)
    vim.bo[output_buf].modifiable = false
    for _, win in ipairs(vim.fn.win_findbuf(output_buf)) do
      vim.api.nvim_win_set_cursor(win, { #lines, 0 })
    end
  end

  reload_log()

  editor = Snacks.win({
    file = file,
    bo = {
      modifiable = true,
    },
    ft = "lua",
    keys = {
      ["source"] = {
        "<cr>",
        ---@param self snacks.win
        function(self)
          local lua = self:lines()
          resp.write(resp.create_from_req(req, {
            type = "run",
            lua = table.concat(lua, "\n"),
          }))
        end,
        desc = "Run",
        mode = { "n", "x" },
      },
      ["focus_output"] = {
        "<leader>wl",
        function()
          if output then
            output:focus()
          end
        end,
        desc = "Focus output",
        mode = { "n" },
      },
      ["no-left-win"] = {
        "<leader>wh",
        function()
          if output then
            output:focus()
          end
        end,
        desc = "Focus output",
        mode = { "n" },
      },
      ["q"] = {
        "q",
        "<Nop>",
        desc = "Focus output",
        mode = { "n" },
      },
    },
  })

  output = Snacks.win({
    buf = output_buf,
    keys = {
      ["focus_editor"] = {
        "<leader>wh",
        function()
          if editor then
            editor:focus()
          end
        end,
        desc = "Focus Editor",
        mode = { "n" },
      },
      ["no-right-win"] = {
        "<leader>wl",
        function()
          if editor then
            editor:focus()
          end
        end,
        desc = "Focus output",
        mode = { "n" },
      },
      ["q"] = {
        "q",
        "<Nop>",
        desc = "Focus output",
        mode = { "n" },
      },
    },
  })

  local layout = Snacks.layout.new({
    show = true,
    wins = { editor = editor, output = output },
    layout = {
      position = "float",
      box = "horizontal",
      width = 0.8,
      height = 0.8,
      {
        win = "editor",
        title = "Wezterm Lua Source Code",
        border = "rounded",
      },
      {
        win = "output",
        title = "Debug Logs",
        border = "rounded",
      },
    },
  })

  layout:show()

  config.debug.handles[req.id] = {
    handle = function(data)
      if data and data.result then
        vim.print(data.result)
      end

      reload_log()
    end,
    layout = layout,
  }
end

function M._debug_nvim()
  local cwd = vim.fn.getenv("VNIX_PLUGIN_DIR")
  local file = string.format("%s/.nvim/nvim.lua", cwd)

  Snacks.scratch.open({
    file = file,
    ft = "lua",
    win = {
      on_close = function()
        M.close()
      end,
    },
  })
end

function M._show_rpc()
  local items = {}

  for _, v in ipairs(config.rpc) do
    if not v.req then
      goto continue
    end

    table.insert(items, {
      text = string.format("%d) %s | %s", v.req.id, v.req.type, v.req.timestamp),
      preview = {
        ft = "json",
        text = vim.fn.system("echo '" .. vim.json.encode(v) .. "' | jq '.'"),
      },
      value = v,
    })

    ::continue::
  end

  Snacks.picker({
    title = "RPC Debug",
    show_empty = true,
    items = items,
    format = "text",
    preview = "preview",
    auto_confirm = false,
    win = {
      preview = {
        keys = {
          ["<leader>r"] = { "reply-req", mode = { "n" } },
          ["<leader>R"] = { "reply-resp", mode = { "n" } },
        },
      },
    },
    actions = {
      ["reply-req"] = function(_, item)
        ---@cast item { value: RPCDebug }
        vim.print(item.value.req)
      end,
      ["reply-resp"] = function(_, item)
        ---@cast item { value: RPCDebug }
        resp.write(item.value.resp)
      end,
    },
  })
end

---@param req UIMessageDebugReq
function M.handle(req)
  if req.data and config.debug.handles[req.data.id] then
    local handle = config.debug.handles[req.data.id]

    if handle then
      handle.handle(req.data)
    end

    return
  end

  ---@alias DebugOpt 'Wezterm' | 'Nvim' | 'RPC'
  ---@type table<DebugOpt>
  local options = {
    "Wezterm",
    "Nvim",
    "RPC",
  }

  vim.ui.select(
    options,
    {
      prompt = "Select Debug Target",
      format_item = function(item)
        ---@cast item string
        local formatted = item:gsub("^%l", string.upper)
        return formatted
      end,
    },
    ---cb
    ---@param item DebugOpt
    function(item)
      if item == "Wezterm" then
        M._debug_wezterm(req)
      elseif item == "Nvim" then
        M._debug_nvim()
      elseif item == "RPC" then
        M._show_rpc()
      end
    end
  )
end

return M
