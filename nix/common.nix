{
  pkgs,
  nixvim,
  system,
  np,
  ...
}: {
  vnix-nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
    inherit pkgs;

    module = {
      imports = [
        ./vnix-nvim.nix
      ];
    };

    extraSpecialArgs = {
      inherit np;
      inherit (pkgs) stdenv;
    };
  };
}
