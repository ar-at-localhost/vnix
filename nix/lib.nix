{lib}: let
  types = let
    paneSpec = lib.types.submodule {
      options = {
        workspace = lib.types.str;
        tab = lib.types.str;
        name = lib.types.str;
        cwd = lib.types.nullOr lib.types.str;
        args = lib.types.nullOr (lib.types.listOf lib.types.str);
        args_mode = lib.types.nullOr lib.types.str;
        left = lib.types.nullOr lib.types.int;
        right = lib.types.nullOr lib.types.int;
        top = lib.types.nullOr lib.types.int;
        bottom = lib.types.nullOr lib.types.int;
        first = lib.types.nullOr (lib.types.enum ["right" "bottom"]);
        env = lib.types.nullOr (lib.types.attrsOf lib.types.str);
        spec_type = lib.types.str;
      };
    };

    layoutSpec = lib.types.submodule {
      options = {
        name = lib.types.str;
        layout = lib.types.str;
        cwd = lib.types.nullOr lib.types.str;
        opts = lib.types.attrs;
        spec_type = lib.types.str;
      };
    };
  in {
    inherit paneSpec layoutSpec;
    spec = lib.types.oneOf [paneSpec layoutSpec];
  };

  mkPaneSpec = {
    workspace,
    tab,
    name,
    cwd ? null,
    args ? null,
    args_mode ? null,
    left ? null,
    right ? null,
    top ? null,
    bottom ? null,
    first ? null,
    env ? null,
  }:
    {
      inherit workspace tab name;
      spec_type = "pane";
    }
    // (lib.optionalAttrs (cwd != null) {inherit cwd;})
    // (lib.optionalAttrs (args != null) {inherit args;})
    // (lib.optionalAttrs (args_mode != null) {inherit args_mode;})
    // (lib.optionalAttrs (left != null) {inherit left;})
    // (lib.optionalAttrs (right != null) {inherit right;})
    // (lib.optionalAttrs (top != null) {inherit top;})
    // (lib.optionalAttrs (bottom != null) {inherit bottom;})
    // (lib.optionalAttrs (first != null) {inherit first;})
    // (lib.optionalAttrs (env != null) {inherit env;});

  mkLayoutSpec = {
    name,
    layout,
    cwd ? null,
    opts ? {},
  }: {
    inherit layout;
    spec_type = "layout";
    opts =
      opts
      // {
        inherit name;
      }
      // (lib.optionalAttrs (cwd != null) {inherit cwd;});
  };
in {
  inherit mkPaneSpec mkLayoutSpec types;
}
