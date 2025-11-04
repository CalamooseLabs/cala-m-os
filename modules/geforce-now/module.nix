{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.geforce-now;
in {
  options.services.geforce-now = {
    enable = mkEnableOption "GeForce Now Flatpak with Wayland support";
  };

  config = mkIf cfg.enable {
    services.flatpak = {
      enable = true;

      remotes = {
        "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        "GeForceNOW" = "https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo";
      };

      packages = [
        "GeForceNOW:app/com.nvidia.geforcenow/x86_64/stable"
      ];

      overrides = {
        "global".Context = {
          sockets = [
            "!x11"
            "!fallback-x11"
            "wayland"
          ];
        };

        # Fix for window not opening on Wayland
        "com.nvidia.geforcenow" = {
          Environment = {
            "GDK_BACKEND" = "wayland";
            "XDG_SESSION_TYPE" = "wayland";
            "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
            "EGL_PLATFORM" = "wayland";
          };
          Context = {
            sockets = [
              "wayland"
              "!x11"
              "!fallback-x11"
            ];
            devices = [
              "all"
            ];
          };
        };
      };
    };
  };
}
