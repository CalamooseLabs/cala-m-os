##################################
#                                #
#        Home Theater PC         #
#                                #
##################################
{
  pkgs,
  lib,
  ...
}: let
  import_users = ["gamer"];

  machine_type = "VM";
  machine_uuid = "Large";
in {
  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = "htpc";

  # Audio Control
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.xserver.enable = true;

  # CRITICAL: Disable llvmpipe completely
  # environment.variables = {
  #   LIBGL_ALWAYS_SOFTWARE = "0";
  #   __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  #   __VK_LAYER_NV_optimus = "NVIDIA_only";
  #   VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
  #   MESA_LOADER_DRIVER_OVERRIDE = "nvidia";
  # };

  # hardware.graphics = {
  #   enable = true;
  #   enable32Bit = true; # Was driSupport32Bit

  #   extraPackages = with pkgs; [
  #     nvidia-vaapi-driver
  #     vulkan-loader
  #     vulkan-validation-layers
  #   ];

  #   extraPackages32 = with pkgs.pkgsi686Linux; [
  #     vulkan-loader
  #   ];
  # };

  microvm = {
    optimize.enable = false;
    baloon = lib.mkForce false;

    # Use VM's own store disk as base
    storeOnDisk = true;

    # Enable writable overlay for building
    writableStoreOverlay = "/nix/.rw-store";

    # Persistent volume for the overlay
    volumes = [
      {
        image = "nix-store-overlay.img";
        mountPoint = "/nix/.rw-store";
        size = 51200; # 50GB
        autoCreate = true;
        fsType = "ext4";
      }
    ];
  };
}
