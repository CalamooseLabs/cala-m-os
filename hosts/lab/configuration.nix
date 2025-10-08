##################################
#                                #
#           Lab Server           #
#                                #
#     Used for the Following:    #
#     - HTPC                     #
#     - Plex Server              #
#     - Studio Stream            #
#     - Torrent Manager          #
#                                #
##################################
{
  lib,
  initialInstallMode,
  ...
}: let
  users = ["server"];

  machine_type = "Workstation";
  machine_uuid = "TRX50-SAGE";
in {
  imports =
    [
      (import ../_core/default.nix {
        users_list = users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
      })
    ]
    ++ lib.optional (!initialInstallMode) ./vms.nix;

  networking.hostName = "lab";

  boot.kernelModules = [
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
  ];

  # Only blacklist NVIDIA GPU drivers
  boot.blacklistedKernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "nvidiafb"
    "nouveau"
    "snd_hda_intel"
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.variables = {
    ROC_ENABLE_PRE_VEGA = "1";
  };

  # Bind GPUs so they don't get confused
  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:2b85,10de:22e8,10de:2882,10de:22be
  '';
}
