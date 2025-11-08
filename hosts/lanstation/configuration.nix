##################################
#                                #
#        Lan Station Host        #
#                                #
##################################
{
  lib,
  cala-m-os,
  initialInstallMode,
  ...
}: let
  import_users = ["gamer"];

  machine_type = "Workstation";
  machine_uuid = "TRX50-SAGE";
in {
  imports =
    [
      # Common Core Config
      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
      })
    ]
    ++ lib.optional (!initialInstallMode) ./vms.nix;

  networking.hostName = "lanstation-1";

  networking.networkmanager.enable = lib.mkForce false;

  networking = {
    interfaces.eno2 = {
      ipv4.addresses = [
        {
          address = cala-m-os.ip.lanstation-1;
          prefixLength = 26;
        }
      ];
    };
    defaultGateway = {
      address = cala-m-os.ip.gateway;
      interface = "eno2";
    };
  };

  boot.kernelModules = [
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
    "vfio_virqfd"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "nvidiafb"
    "nouveau"
  ];

  boot.initrd.kernelModules = [
    # NVIDIA modules first (for host RTX 5090)
    # "nvidia"
    # "nvidia_modeset"
    # "nvidia_drm"
    # "nvidia_uvm"

    # VFIO modules second (for AMD passthrough)
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  # Only blacklist AMD GPU drivers
  boot.blacklistedKernelModules = [
    "amdgpu"
    "radeon"
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Audio Control
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # services.resolved = {
  #   enable = true;
  # };
}
