local resp = require("nvim.resp")

---@class VnixVNimDebugHandle
---@field handle fun(data: UIMessageDebugReqReplyData)
---@field layout? snacks.layout

---@class VnixVNimDebug
---@field _debug_wezterm fun(req: UIMessageDebugReq)
---@field _debug_nvim fun()
---@field handles VnixVNimDebugHandle[]
local M = {
  handles = {},
} ---@type VnixVNimDebug

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

  local output_buf = vim.fn.bufadd(log_file)
  vim.fn.bufload(output_buf)
  vim.api.nvim_buf_set_name(output_buf, log_file)
  vim.bo[output_buf].readonly = true
  vim.bo[output_buf].modifiable = true
  vim.bo[output_buf].autoread = true
  vim.bo[output_buf].swapfile = false

  editor = Snacks.win({
    file = file,
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
        "<leader>l",
        function()
          if output then
            output:focus()
          end
        end,
        desc = "Focus output",
        mode = { "n" },
      },
    },
  })

  output = Snacks.win({
    buf = output_buf,
    keys = {
      ["focus_editor"] = {
        "<leader>h",
        function()
          if editor then
            editor:focus()
          end
        end,
        desc = "Focus Editor",
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

  M.handles[req.id] = {
    handle = function(data)
      if output and data then
        vim.bo[output_buf].readonly = false
        local lines = vim.split(data.result or "", "\n", { plain = true })
        vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, lines)
        vim.bo[output_buf].readonly = true
      end
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

---@param req UIMessageDebugReq
function M.handle(req)
  if req.data and M.handles[req.data.id] then
    local handle = M.handles[req.data.id]

    if handle then
      handle.handle(req.data)
    end

    return
  end

  local options = {
    "Wezterm",
    "Nvim",
  }

  vim.ui.select(options, {
    prompt = "Select Debug Target",
    format_item = function(item)
      ---@cast item string
      local formatted = item:gsub("^%l", string.upper)
      return formatted
    end,
  }, function(item)
    if item == "Wezterm" then
      M._debug_wezterm(req)
    elseif item == "Nvim" then
      M._debug_nvim()
    end
  end)
end

return M
