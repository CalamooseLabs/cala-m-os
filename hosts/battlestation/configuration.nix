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

  networking.hostName = "battlestation";

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
  ];

  # Only blacklist AMD GPU drivers
  boot.blacklistedKernelModules = [
    "amdgpu"
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
