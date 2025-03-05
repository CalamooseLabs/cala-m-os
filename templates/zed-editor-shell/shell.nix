{ pkgs, inputs }:

let
  zedWrapper = import "${inputs.zed-wrapper}/wrappers/zed-editor/default.nix" { inherit pkgs; };

  # Define your zed settings
  zedSettings = {
    "vim_mode" = false;
    "relative_line_numbers" = false;
    "load_direnv" = "shell_hook";
  };
in
pkgs.mkShell {
  buildInputs = [
    (zedWrapper zedSettings)
  ];

  shellHook = ''
    echo "Using wrapped local zed: ./.direnv/.config/zed"
  '';
}
