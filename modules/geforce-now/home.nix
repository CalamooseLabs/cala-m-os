{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    inputs.flatpaks.homeModules.default
  ];

  # Define the GPU type option
  options = {
    geforceNow.gpuType = lib.mkOption {
      type = lib.types.enum ["intel" "nvidia" "amd"];
      default = "amd";
      description = "GPU type for GeForce NOW optimization";
    };
  };

  config = {
    home.packages = [
      pkgs.flatpak
    ];

    home.sessionPath = [
      "$HOME/.local/share/flatpak/exports/bin"
      "/var/lib/flatpak/exports/bin"
    ];

    # Add Flatpak share directories to XDG_DATA_DIRS (as string)
    home.sessionVariables = {
      XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/share:/usr/local/share:$XDG_DATA_DIRS";
    };

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

      overrides = {
        "com.nvidia.geforcenow" = {
          Context = {
            sockets = [
              "!wayland"
            ];
          };
          # Set proper environment variables based on GPU type
          Environment = lib.mkMerge [
            # Intel GPU configuration
            (lib.mkIf (config.geforceNow.gpuType == "intel") {
              VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
              MESA_LOADER_DRIVER_OVERRIDE = "iris";
              ANV_DEBUG = "video-decode,video-encode";
            })
            # NVIDIA GPU configuration
            (lib.mkIf (config.geforceNow.gpuType == "nvidia") {
              VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
              MESA_LOADER_DRIVER_OVERRIDE = "nvidia";
            })
          ];
        };
      };
    };
  };
}
