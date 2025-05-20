{lib, ...}: {
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = lib.mkForce true;
        grace = lib.mkForce 0;
        hide_cursor = lib.mkForce false;
        no_fade_in = lib.mkForce false;
      };

      auth = {
        fingerprint = {
          enabled = true;
        };
      };

      background = lib.mkForce [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = lib.mkForce [
        {
          size = lib.mkForce "200, 50";
          position = lib.mkForce "0, -80";
          monitor = lib.mkForce "";
          dots_center = lib.mkForce true;
          fade_on_empty = lib.mkForce false;
          outline_thickness = lib.mkForce 5;
          placeholder_text = lib.mkForce ''
            <span>Password...</span>
          '';
          shadow_passes = lib.mkForce 2;
        }
      ];
    };
  };

  wayland.windowManager.hyprland = {
    settings = {
      exec-once = [
        "hyprlock"
      ];

      bind = ["$mod, L, exec, hyprlock"];
    };
  };
}
