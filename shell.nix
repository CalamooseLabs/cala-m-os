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
    (inputs.antlers.packages.x86_64-linux.zed-editor zedSettings)
  ];

  shellHook = ''
    echo "Using Local Nix-Enabled Zed!"
  '';
}
