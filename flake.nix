{
  description = "Development environment for VNix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    np = {
      url = "github:ar-at-localhost/np/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    nixvim,
    np,
    ...
  }:
    {
      modules = {
        lib = import ./nix/lib.nix;
      };

      homeManagerModules = {
        default = import ./nix/home-manager.nix;
        vnix = import ./nix/home-manager.nix;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };

        vnixDevPkgs = import ./nix/dev-pkgs.nix {
          inherit pkgs system nixvim np;
        };
      in {
        formatter = pkgs.alejandra;
        devShells.default = pkgs.mkShell {
          name = "vnix-dev";

          packages = with pkgs; [
            alejandra
            biome
            lefthook
            lua
            luarocks
            luaPackages.busted
            stylua
            lua-language-server
            (import ./nix/nixvim.nix {inherit system pkgs nixvim np wezterm-types;})
            vnixDevPkgs.vnix
          ];

          shellHook = ''
            if [ ! -f .git/hooks/pre-commit ] || ! grep -q lefthook .git/hooks/pre-commit 2>/dev/null; then
              lefthook install
            fi

            export WEZTERM_LUA_TYPES="${vnixDevPkgs.wezterm-types}/share/lua/5.4"
          '';
        };
      }
    );
}
