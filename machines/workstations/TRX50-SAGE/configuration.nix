##################################
#                                #
#  ASUS Pro WS TRX50-Sage WiFi   #
#  AMD Ryzen Threadripper 7960X  #
#    64GB ECC DDR5 6000 CL32     #
#    ASUS RTX5090 ROG Astral     #
# Intel Arc A750 Limited Edition #
#                                #
##################################
{pkgs, ...}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix

    # Modules
    ./modules/nvidia-rtx5090/configuration.nix
    ./modules/intel-arc750/configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia.prime = {
    intelBusId = "PCI:44:0:0";
    nvidiaBusId = "PCI:41:0:0";
  };

  users.users.hub.extraGroups = ["libvirtd"];
}
