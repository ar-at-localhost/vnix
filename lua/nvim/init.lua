local M = {}

---@param opts VNixNvimOpts
function M.setup(opts)
  local o = require("nvim.config")
  if o and o.vnix_dir and o.vnix_dir ~= "" then
    return
  end

  if opts and opts.vnix_dir then
    o.vnix_dir = opts.vnix_dir

    local src = os.getenv("VNIX_PLUGIN_DIR")
    if src and src ~= "" then
      o.src_dir = src .. "/lua"
    end

    o._ns = vim.api.nvim_create_namespace("vnix")
    require("nvim.pickers")()
    require("nvim.dashboard")()
    require("nvim.fs-watch").setup()
  end
end

return M
