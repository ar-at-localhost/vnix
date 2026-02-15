local M = {}

---@param opts VNixNvimOpts
function M.setup(opts)
  local o = require("vnix-nvim.vnix")
  if o and o.vnix_dir and o.vnix_dir ~= "" then
    return
  end

  if opts and opts.vnix_dir then
    o.vnix_dir = opts.vnix_dir
    require("vnix-nvim.dashboard")()
    require("vnix-nvim.fs-watch")()
  end
end

return M
