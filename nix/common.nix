{
  pkgs,
  nixvim,
  system,
  np,
  ...
}: let
  org-bullets = pkgs.vimUtils.buildVimPlugin {
    name = "org-bullets";
    src = pkgs.fetchFromGitHub {
      owner = "nvim-orgmode";
      repo = "org-bullets.nvim";
      rev = "main";
      hash = "sha256-/l8IfvVSPK7pt3Or39+uenryTM5aBvyJZX5trKNh0X0=";
    };
  };

  org-modern = pkgs.vimUtils.buildVimPlugin {
    name = "org-modern";
    src = pkgs.fetchFromGitHub {
      owner = "danilshvalov";
      repo = "org-modern.nvim";
      rev = "main";
      hash = "sha256-TYs3g5CZDVXCFXuYaj3IriJ4qlIOxQgArVOzT7pqkqs=";
    };
  };

  headlines = pkgs.vimUtils.buildVimPlugin {
    name = "headlines";
    src = pkgs.fetchFromGitHub {
      owner = "lukas-reineke";
      repo = "headlines.nvim";
      rev = "master";
      hash = "sha256-LWYYVnLZgw6DhO/n0rclQVnon5TvyQVUGb2smaBzcPg=";
    };
  };
in {
  vnix-nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
    module = {
      imports = [
        np.nixvimModules.base
      ];

      # TODO: Contribute to `plugins.orgmode` instead
      extraPlugins = [pkgs.vimPlugins.orgmode org-bullets org-modern headlines];

      extraConfigLua = ''
        function _M.setup_orgmode(opts)
        local Menu = require("org-modern.menu")
        require('orgmode').setup({
          org_agenda_files = opts.org_agenda_files,
          org_default_notes_file = opts.org_default_notes_file,

          ui = {
            menu = {
              handler = function(data)
            Menu:new():open(data)
              end,
            },
          },
        })

        require("org-bullets").setup()
        require("headlines").setup({
          markdown = {
            headline_highlights = false,
          }
        })

        vim.lsp.enable('org')
        end

        require('nvim.setup')
      '';

      plugins = {
        blink-cmp.settings = {
          sources = {
            per_filetype = {
              org = ["orgmode"];
            };

            providers = {
              orgmode = {
                name = "Orgmode";
                module = "orgmode.org.autocompletion.blink";
                fallbacks = ["buffer"];
              };
            };
          };
        };

        which-key.settings.spec = [
          {
            __unkeyed-1 = "<leader>o";
            group = "Orgmode";
            icon = "";
          }
          {
            __unkeyed-1 = "<leader>v";
            group = "Vnix";
            icon = "";
          }
        ];

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
    };
  };
}
