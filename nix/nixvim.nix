{
  lib,
  np,
  pkgs,
  ...
}: {
  imports = [
    np.nixvimModules.base
    np.nixvimModules.xtras.orgmode
  ];

  plugins.lazydev.enable = lib.mkForce false;

  env = {
    NVIM_SNACKS_LUA_TYPES = "${pkgs.vimPlugins.snacks-nvim}/lua/snacks";
    NVIM_ORGMODE_LUA_TYPES = "${pkgs.vimPlugins.orgmode}/lua/orgmode";
  };
}
