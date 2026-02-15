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

  cwd = builtins.getEnv "CWD";

  repo_path =
    if cwd == ""
    then (toString ../.)
    else cwd;

  plugin_dir =
    if cwd == ""
    then "./"
    else cwd;

  example_vnix_config_orig = builtins.readFile ./dev/example-vnix-config.json;
  example_vnix_config = builtins.replaceStrings ["_cwd_"] [(toString ../.)] example_vnix_config_orig;
  example_wezterm_cfg = builtins.readFile ./dev/example-wezterm-config.lua;

  config_json = pkgs.writeTextFile {
    name = "config.json";
    text = example_vnix_config;
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
      cp ${config_json} $out/config.json
      cp ${wezterm_lua} $out/wezterm.lua
    '';
  };

  inherit (common) vnix-nvim;
  wezterm-types-version = "1.4.0-1";
in {
  inherit vnix-nvim;
  inherit repo_path;

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

        makeWrapper ${pkgs.wezterm}/bin/wezterm \
        $out/bin/vnix \
        --set XDG_CONFIG_HOME "/tmp/vnix-dev/config" \
        --set XDG_DATA_HOME   "/tmp/vnix-dev/data" \
        --set XDG_CACHE_HOME  "/tmp/vnix-dev/cache" \
        --set VNIX_PLUGIN_DIR "${plugin_dir}" \
        --prefix LUA_PATH ";" "${repo_path}/?.lua;${repo_path}/?/init.lua" \
        --run "
        rm -rf /tmp/vnix-dev
        mkdir -p /tmp/vnix-dev/config /tmp/vnix-dev/data /tmp/vnix-dev/cache
        cp ${vnixWeztermDevConfig}/config.json /tmp/vnix-dev/
        cp ${vnixWeztermDevConfig}/wezterm.lua /tmp/vnix-dev/
        " \
        --add-flags "--config-file /tmp/vnix-dev/wezterm.lua" \
        --add-flags "start --always-new-process"

        makeWrapper ${vnix-nvim}/bin/nvim \
        $out/bin/vnix-nvim \
        --set VNIX_PLUGIN_DIR "${plugin_dir}" \
        --prefix LUA_PATH ";" "${repo_path}/?.lua;${repo_path}/?/init.lua"

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
