{ pkgs, ... }:

let
  zedWrapper = import ./wrappers/zed-editor { inherit pkgs; };

  zedSettings = {
    lsp = {
      nix = {
        binary = {
          path_lookup = true;
        };
      };
    };

    auto_install_extensions = {
      "nix" = true;
    };
  };
in
pkgs.mkShell {
  buildInputs = [
    pkgs.nixd
    pkgs.nil
    (zedWrapper zedSettings)
  ];

  shellHook = ''
    echo "Using wrapped local zed: ./.direnv/.config/zed"
  '';
}
