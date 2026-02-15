{
  np,
  pkgs,
  ...
}: {
  imports = [
    np.nixvimModules.base
    ./orgmode.nix
  ];

  plugins = {
    csvview = {
      enable = true;
      settings.view.display_mode = "border";
    };

    snacks.settings.dashboard = {
      enabled = true;
      sections = {
        section = "header";
      };
    };
  };

  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "vnix-nvim";
      src = ../vnix-nvim;
    })
  ];

  extraConfigLua = ''
    require('vnix-nvim').setup()
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>vc";
      action = "<cmd>Vnix close<CR>";
      options.desc = "Close";
    }
    {
      mode = "n";
      key = "<leader>vs";
      action = "<cmd>Vnix switch<CR>";
      options.desc = "Switch / Search";
    }
    {
      mode = "n";
      key = "<leader>vv";
      action = "<cmd>Vnix<CR>";
      options.desc = "Dashboard";
    }
  ];

  plugins.which-key.settings.spec = [
    {
      __unkeyed-1 = "<leader>v";
      group = "Vnix";
      icon = "";
    }
  ];
}
