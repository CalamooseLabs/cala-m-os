{
  inputs,
  pkgs,
  ...
}: let
  zedSettings = {
    lsp = {
      nix = {
        binary = {
          path_lookup = true;
        };
      };
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
      nix = {
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
      (inputs.antlers.packages.x86_64-linux.zed-editor zedSettings)
    ];

    shellHook = ''
      echo "Using Local Nix-Enabled Zed!"
    '';
  }
