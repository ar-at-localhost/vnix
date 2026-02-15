{
  pkgs,
  nixvim,
  system,
  np,
  ...
}: let
  common = import ./common.nix {
    inherit pkgs nixvim system np;
  };

  vnixWeztermLua = pkgs.stdenv.mkDerivation {
    pname = "vnixWeztermLua";
    inherit (pkgs.wezterm) version;
    src = ./..;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out
      cat > $out/wezterm.lua <<'EOF'
         local wezterm = require("wezterm")
         local config = wezterm.config_builder()

         config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1001 }
         config.font = wezterm.font('Fira Code Nerd Font')
         config.font_size = 11
         config.enable_tab_bar = true
         config.use_fancy_tab_bar = false
         config.tab_max_width = 0
         config.hide_tab_bar_if_only_one_tab = false
         config.show_new_tab_button_in_tab_bar = false
         config.status_update_interval = 60000
         config.window_decorations = "NONE"
         config.mouse_wheel_scrolls_tabs = false;
         config.default_cursor_style = "BlinkingBlock";

         config.unix_domains = {
          {
            name = "vnix-dev",
          },
         }

         -- Add your vnix common plugin path
         package.path = package.path .. ";/path/to/vnix-common/?.lua;/path/to/vnix-common/?/init.lua"

         -- Load vnix plugin
         -- FIXME: Hard-coded
         local vnix = wezterm.plugin.require("https://github.com/ar-at-localhost/vnix")
         vnix.apply_to_config(config, {
           vnix_dir = "/tmp/vnix",
           workspaces_file = "/home/ar/.vvx/panes.json",
           debug = true
         })
         return config
      EOF
    '';
  };

  inherit (common) vnix-nvim;
  wezterm-types-version = "1.4.0-1";
in {
  inherit vnix-nvim;

  vnix =
    pkgs.stdenv.mkDerivation
    {
      pname = "vnix";
      inherit (pkgs.wezterm) version;
      buildInputs = [pkgs.makeWrapper pkgs.wezterm vnixWeztermLua vnix-nvim];
      src = ./..;

      installPhase = ''
         mkdir -p $out/bin $out/lib
         cp -r ${../vnix-common} $out/lib/vnix-common

         makeWrapper ${pkgs.wezterm}/bin/wezterm \
         $out/bin/vnix \
         --set XDG_CONFIG_HOME "/tmp/vnix/config" \
         --set XDG_DATA_HOME   "/tmp/vnix/data" \
         --set XDG_CACHE_HOME  "/tmp/vnix/cache" \
        --prefix LUA_PATH ";" "$out/lib/?.lua;$out/lib/?/init.lua" \
         --run "rm -rf /tmp/vnix/config /tmp/vnix/data /tmp/vnix/cache && mkdir -p /tmp/vnix/config /tmp/vnix/data /tmp/vnix/cache && ${pkgs.wezterm}/bin/wezterm --config-file ${vnixWeztermLua}/wezterm.lua start --always-new-process"

         makeWrapper ${vnix-nvim}/bin/nvim \
         $out/bin/vnix-nvim \
        --prefix LUA_PATH ";" "$out/lib/?.lua;$out/lib/?/init.lua"

         ln -s ${vnix-nvim}/bin/nixvim-print-init \
         $out/bin/vnix-print-nvim-init
      '';
    };

  wezterm-types = pkgs.stdenv.mkDerivation {
    pname = "wezterm-types";
    version = wezterm-types-version;
    src = pkgs.fetchFromGitHub {
      owner = "DrKJeff16";
      repo = "wezterm-types";
      rev = "4179269";
      hash = "sha256-/lSPtDKCw5pju9363xdPlZIzS0Zo2NCdnkVniv17nA0=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/lua/5.4
      cp -r lua/wezterm/types/. $out/share/lua/5.4/
      runHook postInstall
    '';
  };
}
