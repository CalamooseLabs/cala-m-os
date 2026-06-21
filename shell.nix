{
  inputs,
  pkgs,
  ...
}: let
  zedSettings = {
    lsp = {
      nil = {
        initialization_options = {
          formatting = {
            command = [
              "alejandra"
              "--quiet"
              "--"
            ];
          };
        };
      };
      nixd = {
        initialization_options = {
          formatting = {
            command = [
              "alejandra"
              "--quiet"
              "--"
            ];
          };
        };
      };
    };

    auto_install_extensions = {
      "nix" = true;
    };

    languages = {
      "Nix" = {
        formatter = {
          external = {
            command = "alejandra";
            arguments = [
              "--quiet"
              "--"
            ];
          };
        };
      };
    };
  };
in
  pkgs.mkShell {
    buildInputs = [
      pkgs.alejandra
      pkgs.nixd
      pkgs.nil
      pkgs.claude-code
      # flash-iso now ships from the antlers scripts collection (relocated out of
      # this file). Defaults to building this repo's iso from the git toplevel.
      inputs.antlers.packages.${pkgs.stdenv.hostPlatform.system}.flash-iso
      (inputs.antlers.lib.x86_64-linux.mkZedWrapper zedSettings)
    ];

    shellHook = ''
      echo "Using Local Nix-Enabled Zed!"
    '';
  }
