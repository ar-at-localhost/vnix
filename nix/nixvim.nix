{
  system,
  pkgs,
  nixvim,
  np,
  wezterm-types,
  ...
}: (nixvim.legacyPackages.${system}.makeNixvimWithModule {
  inherit pkgs;

  module = {
    imports = [
      np.nixvimModules.base
      np.nixvimModules.xtras.orgmode
    ];

    env = {
      NVIM_SNACKS_LUA_TYPES = "${pkgs.vimPlugins.snacks-nvim}/lua";
      NVIM_ORGMODE_LUA_TYPES = "${pkgs.vimPlugins.orgmode}/lua/orgmode";
    };

    plugins.none-ls.sources.diagnostics.selene.enable = true;

    extraConfigLuaPost = ''
      local orgmode = require("orgmode")
      orgmode.destroy()

      local org_paths = { string.format("%s/orgfiles/**/*.org", _M.dirs.root) }
      local org_notes_path = string.format("%s/orgfiles/notes.org", _M.dirs.root)
      local keywords = { "TODO", "PROG", "|", "DONE", "CLOSED" }

      local Menu = require("org-modern.menu")
      orgmode.setup({
        org_agenda_files = org_paths,
        org_default_notes_file = org_notes_path,
        org_todo_keywords = keywords,

        ui = {
          menu = {
            handler = function()
              Menu:new():open()
            end,
          },
        },
      })

      require("org-bullets").setup()
      require("headlines").setup({
        markdown = {
          headline_highlights = false,
        },
      })
    '';
  };

  extraSpecialArgs = {
    inherit np wezterm-types;
    inherit (pkgs) stdenv;
  };
})
