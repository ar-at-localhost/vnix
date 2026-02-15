local state = require("nvim.state")
local fs = require("common.fs")

local M = {}
local function json_to_attrset(json_str)
  local result = vim
    .system({
      "nix",
      "eval",
      "--expr",
      string.format([[builtins.fromJSON ''%s'']], json_str),
    }, { text = true })
    :wait()

  if result.code ~= 0 then
    return "{}"
  end

  return result.stdout
end

---Handle create Request
---@param req UIMessagePersistReq
function M.handle(req)
  -- Auto-create file if it doesn't exist
  local path = req.data
  if vim.fn.filereadable(path) == 0 then
    local dir = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
    local fd = io.open(path, "w")
    if fd then
      fd:write(vim.json.encode({
        workspaces = state.workspaces_to_specs(),
      }))
      fd:close()
    end
  end

  local tmp = vim.fn.tempname()
  local ft = vim.fn.fnamemodify(path, ":e")
  local out = vim.json.encode(state.workspaces_to_specs())
  if ft == "nix" then
    out = json_to_attrset(out)
  end

  local win = Snacks.win({
    ft = ft,
    text = out,
    show = true,
    title = "Persist Specs",
    border = true,
    bo = {
      buftype = "",
    },
    wo = {
      number = true,
    },

    on_close = function(win)
      local buf = win.buf
      if buf then
        fs.copy_file(tmp, path)
      end
    end,
  })

  local buf = win.buf
  if buf then
    vim.api.nvim_buf_set_name(buf, tmp)
    require("conform").format({
      bufnr = buf,
      formatters = { "alejandra" },
    })
  end

  win:show()
end

return M
