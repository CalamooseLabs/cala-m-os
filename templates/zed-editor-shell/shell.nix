{ pkgs, makeZedWrapped }:

let
  # Define your zed settings
  zedSettings = {
    "vim_mode" = false;
    "relative_line_numbers" = false;
    "load_direnv" = "shell_hook";
  };
in
pkgs.mkShell {
  buildInputs = [
    (makeZedWrapped zedSettings)
  ];

  shellHook = ''
    echo "Using wrapped local zed: ./.direnv/.config/zed"
  '';
}
