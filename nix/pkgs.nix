{
  system,
  pkgs,
  nixvim,
  np,
  vnix_dir,
  ...
}: let
  common = import ./common.nix {
    inherit system pkgs nixvim np;
  };

  inherit (common) vnix-nvim;
in {
  vnix =
    pkgs.stdenv.mkDerivation
    {
      pname = "vnix";
      inherit (pkgs.wezterm) version;
      buildInputs = [pkgs.makeWrapper pkgs.wezterm vnix-nvim];
      src = ../.;
      dontUnpack = true;
      dontBuild = true;

      installPhase = ''
        mkdir -p $out/bin $out/vnix-lua
        cp -rf $src/. $out/vnix-lua/

        makeWrapper ${vnix-nvim}/bin/nvim \
        $out/bin/vnix-nvim \
        --prefix LUA_PATH ";" "$out/vnix-lua/?.lua;$out/vnix-lua/?/init.lua"

        makeWrapper ${pkgs.wezterm}/bin/wezterm $out/bin/vnix \
        --prefix LUA_PATH ";" "$out/vnix-lua/?.lua;$out/vnix-lua/?/init.lua" \
        --add-flags "--config-file \$HOME/${vnix_dir}/wezterm.lua" \
        --add-flags "start" \
        --add-flags "--always-new-process"
      '';
    };
}
