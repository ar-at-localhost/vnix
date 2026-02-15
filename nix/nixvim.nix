{
  system,
  pkgs,
  nixvim,
  np,
  wezterm-types,
  ...
}: (nixvim.legacyPackages.${system}.makeNixvimWithModule {
  inherit pkgs;

  module = {
    imports = [
      np.nixvimModules.base
      np.nixvimModules.xtras.orgmode
    ];

    env = {
      NVIM_SNACKS_LUA_TYPES = "${pkgs.vimPlugins.snacks-nvim}/lua";
      NVIM_ORGMODE_LUA_TYPES = "${pkgs.vimPlugins.orgmode}/lua/orgmode";
    };

    plugins.none-ls.sources.diagnostics.selene.enable = true;
  };

  extraSpecialArgs = {
    inherit np wezterm-types;
    inherit (pkgs) stdenv;
  };
})
