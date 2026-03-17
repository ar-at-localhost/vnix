{
  lib,
  config,
  system,
  pkgs,
  inputs,
  ...
}: let
  vnix_cfg = config.programs.vnix;

  strToNull = s:
    if s == null
    then "nil"
    else "\"${s}\"";

  intToNull = i:
    if i == null
    then "nil"
    else toString i;

  mkNameOption = {description}:
    lib.mkOption {
      inherit description;
      type = lib.types.str;
    };

  mkCwdOption = _:
    lib.mkOption {
      description = "Current working directory";
      type = lib.types.str;
      default = "";
    };

  mkBoolOption = {
    description,
    default,
  }:
    lib.mkOption {
      inherit description default;
      type = lib.types.bool;
    };

  mkSizeOption = _:
    lib.types.submodule {
      options = {
        width = lib.mkOption {
          description = "Width";
          type = lib.types.int;
          default = 50;
        };
        height = lib.mkOption {
          description = "Height";
          type = lib.types.int;
          default = 50;
        };
        relative = mkBoolOption {
          description = "If true, treat width / height as relative %";
          default = true;
        };
      };
    };

  mkPaneType = {description}:
    lib.types.submodule {
      options = {
        name = mkNameOption {inherit description;};
        cwd = mkCwdOption {};

        cmd = lib.mkOption {
          description = ''Command to execute (add ":" at beginning to make it paste only.)'';
          type = lib.types.nullOr (lib.types.listOf lib.types.str);
          default = null;
        };

        right = lib.mkOption {
          description = "Right split";
          type = lib.types.nullOr (mkPaneType {description = "Right split";});
          default = null;
        };

        bottom = lib.mkOption {
          description = "Bottom split";
          type = lib.types.nullOr (mkPaneType {description = "Bottom split";});
          default = null;
        };

        first_split = lib.mkOption {
          description = "Which split to apply first? (defaults to `right` or the only defined.)";
          type = lib.types.enum ["right" "bottom" ""];
          default = "";
        };

        size = lib.mkOption {
          description = "Pane size";
          type = mkSizeOption {};
          default = {};
        };
      };
    };

  mkPaneOption = {description}:
    lib.mkOption {
      inherit description;
      type = mkPaneType {inherit description;};
      default = {};
    };

  mkTabType = _:
    lib.types.submodule {
      options = {
        name = mkNameOption {description = "Tab name";};
        cwd = mkCwdOption {};
        pane = mkPaneOption {description = "Tab pane";};

        lazy = mkBoolOption {
          description = "Lazy load tab";
          default = false;
        };
      };
    };

  mkLayoutOption = _:
    lib.types.submodule {
      options = {
        name = mkNameOption {description = "Layout name";};
        cwd = mkCwdOption {};
        lazy = mkBoolOption {
          description = "Lazy load workspace";
          default = false;
        };
        opts = lib.mkOption {
          description = "Layout specific options.";
          type = lib.types.attrs;
          default = {};
        };
      };
    };

  proc-option = lib.types.submodule {
    options = {
      title = lib.mkOption {
        description = "Proc title";
        type = lib.types.str;
        example = "top";
      };
      cmd = lib.mkOption {
        description = "Proc Command";
        type = lib.types.str;
        example = "top";
      };
      cwd = lib.mkOption {
        description = "Cwd (defaults to vnix_dir for top-level procs and workspace dir for workspace level procs)";
        type = lib.types.nullOr lib.types.str;
        example = "/tmp/top";
        default = null;
      };
      desc = lib.mkOption {
        description = "Description of Proc";
        type = lib.types.nullOr lib.types.str;
        example = "Process moniter";
        default = null;
      };
      autostart = lib.mkOption {
        description = "Flag to automatically start the proc upon Vnix init (for Vnix level procs) or Workspace init (for workspce level procs)";
        type = lib.types.bool;
        default = true;
      };
      interactive = lib.mkOption {
        description = "Flag to mark a proc as an interactive (which will switch to its tab upon creation and let you switch to it later as well).";
        type = lib.types.bool;
        example = true;
        default = false;
      };
    };
  };

  mkWorkspaceType = _:
    lib.types.submodule {
      options = {
        name = mkNameOption {description = "Workspace Name";};

        orgpath = lib.mkOption {
          description = "Orgfiles Path (relative to `cwd`. If omitted, Vnix orgfiles path will be used for this workspace instead.)";
          type = lib.types.nullOr lib.types.str;
          default = "";
        };

        procs = lib.mkOption {
          description = "Procs defination";
          type = lib.types.listOf proc-option;
          default = [];
          example = [
            {
              title = "top";
              cmd = "top -o pid";
              cwd = "/tmp";
              desc = "Process moniter";
              autostart = true;
              interactive = true;
            }
          ];
        };

        layout = lib.mkOption {
          description = "Workspace layout";
          type = mkLayoutOption {};
          default = {};
        };

        tabs = lib.mkOption {
          description = "Tabs List";
          type = lib.types.listOf (mkTabType {});
          default = [];
        };
      };
    };

  pluginCfgType = lib.types.submodule {
    options = {
      vnix_dir = lib.mkOption {
        type = lib.types.str;
        default = ".vnix";
        description = "Vnix directory (relative to files)";
      };

      specs_file_primary = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "vnix.json";
        description = "Primary definition file  (relative to `vnix_dir` or absolute). Can be Nix module's path.";
      };

      specs_file_secondary = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "specs.json";
        description = "Secondary definition file (relative to `vnix_dir`)";
      };

      status_update_interval = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Status update interval in milliseconds";
      };

      specs = lib.mkOption {
        description = "Vnix Specifications";
        type = lib.types.submodule {
          options = {
            workspaces = lib.mkOption {
              description = "Workspaces defination";
              type = lib.types.listOf (mkWorkspaceType {});

              default = [
                {
                  name = "Home";
                  layout = {
                    "name" = "blank";
                    opts = {
                      name = "blank";
                    };
                  };
                }
              ];
            };

            procs = lib.mkOption {
              description = "Procs defination";
              type = lib.types.listOf proc-option;
              default = [];
              example = [
                {
                  title = "top";
                  cmd = "top -o pid";
                  cwd = "/tmp";
                  desc = "Process moniter";
                  autostart = true;
                  interactive = true;
                }
              ];
            };
          };
        };
      };
    };
  };

  weztermConfig = opts: let
    beforeLua =
      if opts.extraLuaBefore != null
      then opts.extraLuaBefore
      else "";

    afterLua =
      if opts.extraLuaAfter != null
      then opts.extraLuaAfter
      else "";

    inherit (opts) cfg;
  in ''
    local wezterm = require("wezterm")
    local config = wezterm.config_builder()

    -- [[BEGIN EXTRA CONFIG LUA BEFORE]]
    do
      ${beforeLua}
    end
    -- [[END EXTRA CONFIG LUA BEFORE]]

    local vnix = require("vnix")
    vnix.apply_to_config(config, {
      vnix_dir = "${cfg.vnix_dir}",
      specs_file_primary = ${strToNull cfg.specs_file_primary},
      specs_file_secondary = ${strToNull cfg.specs_file_secondary},
      status_update_interval = ${intToNull cfg.status_update_interval}
    })

    -- [[BEGIN EXTRA CONFIG LUA AFTER]]
    do
      ${afterLua}
    end
    -- [[END EXTRA CONFIG LUA AFTER]]

    return config
  '';
in {
  options.programs.vnix = {
    enable = lib.mkEnableOption "Vnix terminal multiplexer";

    extraLuaBefore = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Extra Lua configuration before vnix plugin";
    };

    extraLuaAfter = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Extra Lua configuration after vnix plugin";
    };

    cfg = lib.mkOption {
      type = pluginCfgType;
      default = {};
      description = "Vnix plugin configuration";
    };
  };

  config = lib.mkIf vnix_cfg.enable {
    home.file = {
      "${vnix_cfg.cfg.vnix_dir}/vnix.json".text = builtins.toJSON {
        inherit (vnix_cfg.cfg.specs) workspaces;
      };

      "${vnix_cfg.cfg.vnix_dir}/wezterm.lua".text =
        weztermConfig vnix_cfg;
    };

    home.packages = [
      (import ./pkgs.nix {
        inherit system pkgs;
        inherit (inputs) nixvim np;
        inherit (vnix_cfg.cfg) vnix_dir;
      }).vnix
    ];
  };
}
