##################################
#                                #
#         Homelab Server         #
#                                #
#     Used for the Following:    #
#     - Plex Server              #
#     - Torrent Manager          #
#     - *arr Suite               #
#                                #
##################################
{
  lib,
  initialInstallMode,
  cala-m-os,
  ...
}: let
  users = ["server"];

  machine_type = "Workstation";
  machine_uuid = "MS-02";
in {
  imports =
    [
      (import ../_core/default.nix {
        users_list = users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
        extra_user_modules = {};
      })
    ]
    ++ lib.optional (!initialInstallMode) ./vms.nix;

  networking.hostName = "homelab";

  networking.networkmanager.enable = lib.mkForce false;

  networking = {
    interfaces.eno2 = {
      ipv4.addresses = [
        {
          address = cala-m-os.ip.lab.homelab;
          prefixLength = cala-m-os.ip.lab.prefixLength;
        }
      ];
    };
    defaultGateway = {
      address = cala-m-os.ip.lab.gateway;
      interface = "eno2";
    };
  };

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
}
