local M = {}

---@param opts VNixNvimOpts
function M.setup(opts)
  local resp = require("nvim.resp")
  local o = require("nvim.config")
  if (o and o.vnix_dir and o.vnix_dir ~= "") and not o.dev then
    return
  end

  if opts and opts.vnix_dir then
    o.vnix_dir = opts.vnix_dir

    o._ns = vim.api.nvim_create_namespace("vnix")
    require("nvim.pickers")()
    require("nvim.fs-watch").setup()
    require("nvim.org").setup()

    if not o.dev then
      require("nvim.dashboard")()
    end
  end
end

return M
