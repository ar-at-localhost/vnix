{
  lib,
  config,
  system,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.programs.vnix;

  strToNull = s:
    if s == null
    then "nil"
    else "\"${s}\"";

  intToNull = i:
    if i == null
    then "nil"
    else toString i;

  pluginSettingsType = lib.types.submodule {
    options = {
      vnix_dir = lib.mkOption {
        type = lib.types.str;
        default = ".vnix";
        description = "Vnix directory (relative to files)";
      };

      config_file = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Workspaces definition file (relative to `vnix_dir`)";
      };

      status_update_interval = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Status update interval in milliseconds";
      };
    };
  };

  paneSpec = lib.types.submodule {
    options = {
      spec_type = lib.mkOption {
        type = lib.types.enum ["pane"];
        default = "pane";
        description = "Spec discriminator fixed to pane";
      };

      workspace = lib.mkOption {
        type = lib.types.str;
        description = "Workspace name";
      };

      tab = lib.mkOption {
        type = lib.types.str;
        description = "Tab Name";
      };

      name = lib.mkOption {
        type = lib.types.str;
        description = "Pane Name";
      };

      cwd = lib.mkOption {
        type = lib.types.str;
        default = "$HOME";
        description = "Current working directory.";
      };

      args = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Arguments.";
      };

      args_mode = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Arguments mode.";
      };

      right = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Right split ID (1 based index)";
      };

      bottom = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Bottom split ID (1 based index)";
      };

      first = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum ["right" "bottom"]);
        default = null;
        description = "Which split to apply first?";
      };

      env = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
        default = null;
        description = "Environment variables";
      };
    };
  };

  layoutSpec = lib.types.submodule {
    options = {
      spec_type = lib.mkOption {
        type = lib.types.enum ["layout"];
        default = "layout";
        description = "Spec discriminator fixed to layout";
      };

      layout = lib.mkOption {
        type = lib.types.str;
        description = "Layout (to be applied)'s name";
      };

      opts = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
        default = {};
        description = "Layout specific options";
      };
    };
  };

  weztermConfig = vnixCfg: let
    beforeCfg =
      if vnixCfg.extraLuaBefore != null
      then vnixCfg.extraLuaBefore
      else "";

    afterCfg =
      if vnixCfg.extraLuaAfter != null
      then vnixCfg.extraLuaAfter
      else "";

    pluginOpts = vnixCfg.plugin;
  in ''
    local wezterm = require("wezterm")
    local config = wezterm.config_builder()

    -- [[BEGIN EXTRA CONFIG LUA BEFORE]]
    do
      ${beforeCfg}
    end
    -- [[END EXTRA CONFIG LUA BEFORE]]

    local vnix = wezterm.plugin.require("https://github.com/ar-at-localhost/vnix")
    vnix.apply_to_config(config, {
      vnix_dir = "${pluginOpts.vnix_dir}",
      config_file = ${strToNull pluginOpts.config_file},
      status_update_interval = ${intToNull pluginOpts.status_update_interval}
    })

    -- [[BEGIN EXTRA CONFIG LUA AFTER]]
    do
      ${afterCfg}
    end
    -- [[END EXTRA CONFIG LUA AFTER]]

    return config
  '';
in {
  options.programs.vnix = {
    enable = lib.mkEnableOption "Vnix terminal multiplexer";

    panes = lib.mkOption {
      type = lib.types.listOf (lib.types.oneOf [layoutSpec paneSpec]);
      default = [];
      description = "List of pane/layout specifications";
    };

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

    plugin = lib.mkOption {
      type = pluginSettingsType;
      default = {};
      description = "Vnix plugin settings";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      "${cfg.plugin.vnix_dir}/panes.json".text =
        builtins.toJSON cfg.panes;

      "${cfg.plugin.vnix_dir}/wezterm.lua".text =
        weztermConfig cfg;
    };

    home.packages = [
      (import ./pkgs.nix {
        inherit system pkgs;
        inherit (inputs) nixvim np;
        inherit (cfg.plugin) vnix_dir;
      }).vnix
    ];
  };
}
