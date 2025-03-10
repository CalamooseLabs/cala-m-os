{...}: let
  username = builtins.baseNameOf (toString ./.);
  import_programs = [
    "bash"
    "btop"
    "fonts"
    "ghostty"
    "hyprpaper"
    "hyprland"
    "hyprlock"
    "lf"
    "rofi"
    "vivaldi"
    "waybar"
  ];
in {
  imports = [
    (import ../_core {
      username = username;
      import_programs = import_programs;
    })
  ];
}
