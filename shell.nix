{ inputs, pkgs, ... }:

let
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
    (inputs.zed-editor.packages.x86_64-linux.default zedSettings)
  ];

  shellHook = ''
    echo "Using wrapped local zed: ./.direnv/.config/zed"
  '';
}
