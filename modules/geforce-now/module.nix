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
      uninstallUnmanaged = true;
      update.onActivation = true;

      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
        {
          name = "GeForceNOW";
          location = "https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo";
        }
      ];

      packages = [
        {
          appId = "org.freedesktop.Sdk//24.08";
          origin = "flathub";
        }
        {
          appId = "com.nvidia.geforcenow";
          origin = "GeForceNOW";
        }
      ];

      # Wayland-specific overrides for GeForce Now
      overrides = {
        global = {
          # Force Wayland by default
          Context.sockets = ["wayland" "!x11" "!fallback-x11"];

          Environment = {
            MESA_LOADER_DRIVER_OVERRIDE = "";
            VK_ICD_FILENAMES = "";
            ANV_DEBUG = "video-decode,video-encode";
          };
        };
        "com.nvidia.geforcenow".Context = {
          sockets = [
            "wayland"
            "!x11"
            "!fallback-x11"
          ];
        };
      };
    };
  };
}
