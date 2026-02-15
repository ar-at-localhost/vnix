local function is_ok(v)
  return v and v ~= ""
end

vim.api.nvim_create_user_command("Vnix", function(opts)
  ---@type 'setup' | 'switch' | 'dashboard' | 'close'
  local arg = opts.fargs[1]

  if arg == "setup" then
    local vnix = vim.fn.getenv("VNIX")
    local vnix_dir = vim.fn.getenv("VNIX_DIR")

    if is_ok(vnix) and is_ok(vnix_dir) then
      require("vnix-nvim").setup({
        vnix_dir = vnix_dir,
      })
    end
  elseif arg == "switch" then
    require("vnix-nvim.handlers.switch").handle()
  elseif arg == "close" then
    require("vnix-nvim.handlers.switch").handle(true)
  else
    require("vnix-nvim.dashboard")()
  end
end, {
  nargs = "*",
})
