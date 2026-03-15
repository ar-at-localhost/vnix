{
  pkgs,
  nixvim,
  system,
  np,
  ...
}: let
  inherit (pkgs) lib;
  common = import ./common.nix {
    inherit lib pkgs nixvim system np;
  };

  repo = builtins.getEnv "VNIX_PLUGIN_DIR";
  example__vnix__config_orig = builtins.readFile ./dev/example-vnix-specs.json;
  example__vnix__config = builtins.replaceStrings ["_cwd_"] [repo] example__vnix__config_orig;
  example_wezterm_cfg = builtins.readFile ./dev/example-wezterm-config.lua;

  specs_json = pkgs.writeTextFile {
    name = "specs.json";
    text = example__vnix__config;
  };

  wezterm_lua = pkgs.writeTextFile {
    name = "wezterm.lua";
    text = example_wezterm_cfg;
  };

  vnixWeztermDevConfig = pkgs.stdenv.mkDerivation {
    pname = "vnixWeztermLua";
    inherit (pkgs.wezterm) version;
    src = ./..;
    dontBuild = true;
    dontUnpack = true;

    installPhase = ''
      mkdir -p $out
      cp ${specs_json} $out/specs.json
      cp ${wezterm_lua} $out/wezterm.lua
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
      buildInputs = [pkgs.makeWrapper pkgs.wezterm vnixWeztermDevConfig vnix-nvim];
      src = ./..;
      dontBuild = true;
      dontUnpack = true;

      installPhase = ''
        mkdir -p $out/bin
        ln -sf ${pkgs.wezterm}/bin/wezterm $out/bin/vnix-wezterm

        makeWrapper ${pkgs.wezterm}/bin/wezterm \
        $out/bin/vnix \
        --set XDG_CONFIG_HOME "/tmp/vnix-dev/config" \
        --set XDG_DATA_HOME   "/tmp/vnix-dev/data" \
        --set XDG_CACHE_HOME  "/tmp/vnix-dev/cache" \
        --set VNIX_PLUGIN_DIR "${repo}" \
        --prefix LUA_PATH ";" "${repo}/lua/?.lua;${repo}/lua/?/init.lua" \
        --run "
        rm -rf /tmp/vnix-dev
        mkdir -p /tmp/vnix-dev/config /tmp/vnix-dev/data /tmp/vnix-dev/cache
        cp ${vnixWeztermDevConfig}/specs.json /tmp/vnix-dev/
        cp ${vnixWeztermDevConfig}/wezterm.lua /tmp/vnix-dev/
        " \
        --add-flags "--config-file /tmp/vnix-dev/wezterm.lua" \
        --add-flags "start --always-new-process"

        makeWrapper ${vnix-nvim}/bin/nvim \
        $out/bin/vnix-nvim \
        --set VNIX_PLUGIN_DIR "${repo}" \
        --prefix LUA_PATH ";" "${repo}/lua/?.lua;${repo}/lua/?/init.lua"

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
