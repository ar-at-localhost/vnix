local function is_ok(v)
  return v and v ~= ""
end

vim.api.nvim_create_user_command("Vnix", function(opts)
  ---@type 'close' |'dashboard' | 'reload' | 'setup' | 'switch'
  local arg = opts.fargs[1]

  if arg == "reload" then
    local pr = require("plenary.reload")
    pr.reload_module("common")
    pr.reload_module("nvim")
    pr.reload_module("orgmode")
    require("nvim").setup({
      vnix_dir = _G.__vnix.vnix_dir,
    })
  elseif arg == "setup" then
    local vnix = vim.fn.getenv("VNIX")
    local vnix_dir = vim.fn.getenv("VNIX_DIR")

    if is_ok(vnix) and is_ok(vnix_dir) then
      require("nvim").setup({
        vnix_dir = vnix_dir,
      })
    end
  elseif arg == "switch" or arg == "close" then
    require("nvim.handlers.switch").handle(arg == "close")
  else
    require("nvim.dashboard")()
  end
end, {
  nargs = "*",
})
