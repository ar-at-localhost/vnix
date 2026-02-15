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
      src = ./..;

      installPhase = ''
        mkdir -p $out/bin $out/lib
        cp -r ${../vnix-common} $out/lib/vnix-common

        makeWrapper ${vnix-nvim}/bin/nvim \
        $out/bin/vnix-nvim \
        --prefix LUA_PATH ";" "$out/lib/?.lua;$out/lib/?/init.lua"


        makeWrapper ${pkgs.wezterm}/bin/wezterm $out/bin/vnix \
        --prefix LUA_PATH ";" "$out/lib/?.lua;$out/lib/?/init.lua" \
        --add-flags "--config-file \$HOME/${vnix_dir}/wezterm.lua" \
        --add-flags "start" \
        --add-flags "--always-new-process"
      '';
    };
}
