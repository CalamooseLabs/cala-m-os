{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.flatpaks.homeModules.default
  ];

  home.packages = [
    pkgs.flatpak
  ];

  services.flatpak = {
    enable = true;
    forceRunOnActivation = true;

    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "GeForceNOW" = "https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo";
    };

    packages = [
      "flathub:runtime/org.freedesktop.Sdk//24.08"
      "GeForceNOW:app/com.nvidia.geforcenow//master"
    ];

    # Wayland-specific overrides for GeForce Now
    overrides = {
      # global = {
      # Force Wayland by default
      # Context.sockets = ["wayland" "!x11" "!fallback-x11"];
      # };
      "com.nvidia.geforcenow" = {
        Environment = {
          MESA_LOADER_DRIVER_OVERRIDE = "";
          VK_ICD_FILENAMES = "";
          ANV_DEBUG = "video-decode,video-encode";
        };
        Context = {
          sockets = [
            "!wayland"
          ];
        };
      };
    };
  };
}
