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
      # The ISO as a file with a Proton PAT inside (cloud custom-ISO uploads).
      (pkgs.callPackage ./iso/build-pat-iso.nix {})
      (inputs.antlers.lib.x86_64-linux.mkZedWrapper zedSettings)
      # The cheat sheet below; the host list leaves out the two installer images.
      (pkgs.callPackage ./cala-help.nix {
        hosts = builtins.filter (name: !(builtins.elem name ["iso" "installer-kexec"])) (
          builtins.attrNames inputs.self.nixosConfigurations
        );
      })
    ];

    # Print the cheat sheet on the way in (direnv, or an interactive `nix develop`)
    # but not for `nix develop -c ...`, so scripted output stays clean.
    shellHook = ''
      if [ -n "''${DIRENV_IN_ENVRC:-}" ] || [[ $- == *i* ]]; then
        cala-help --banner >&2
      fi
    '';
  }
