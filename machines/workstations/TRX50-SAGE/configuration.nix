##################################
#                                #
#  ASUS Pro WS TRX50-Sage WiFi   #
#  AMD Ryzen Threadripper 7960X  #
#    64GB ECC DDR5 6000 CL32     #
#   RTX 5090 Founders Edition    #
#           RTX 4060             #
#      Intel Arc A310 Omni       #
#                                #
##################################
{pkgs, ...}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix

    # Modules
    ../../modules/nvidia-gpu/configuration.nix
    ../../modules/intel-gpu/configuration.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };

  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci ids=10de:2b85,10de:22e8,10de:2882,10de:22be,1022:14c9"
  ];
}
