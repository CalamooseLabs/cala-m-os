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
  calamoose.version = "2.0.0-beta";

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
    # Host management traffic lives on the 2.5GbE port (eno2), shared with the
    # torrent VM. eno1 (10GbE) is reserved for the media VM's macvtap bridge.
    interfaces.eno2 = {
      ipv4.addresses = [
        {
          address = cala-m-os.ip.lab.homelab;
          prefixLength = cala-m-os.ip.lab.prefixLength;
        }
      ];
    };
    # eno1 carries no host IP; bring the link up but suppress DHCP so the host
    # doesn't grab a stray lease on 10.10.10.0/26 that would collide with eno2.
    # The media VM's macvtap parent needs this interface up.
    interfaces.eno1.useDHCP = false;
    defaultGateway = {
      address = cala-m-os.ip.lab.gateway;
      interface = "eno2";
    };
    nameservers = [cala-m-os.ip.lab.gateway];
  };

  boot.kernelModules = [
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
  ];

  # Enable Intel VT-d explicitly so VFIO can map the B50 into the guest.
  # Passthrough already works on this platform without it, but make it
  # deterministic. Merges with _core's quiet/splash kernelParams.
  boot.kernelParams = ["intel_iommu=on" "iommu=pt"];

  # Only blacklist Intel ARC B50 GPU drivers
  boot.blacklistedKernelModules = [
    "xe"
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
