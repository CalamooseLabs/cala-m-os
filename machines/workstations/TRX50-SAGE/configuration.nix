##################################
#                                #
#  ASUS Pro WS TRX50-Sage WiFi   #
#  AMD Ryzen Threadripper 7960X  #
#    64GB ECC DDR5 6000 CL32     #
#   RTX 5090 Founders Edition    #
#          RX 9060 XT            #
#        AMD PRO W7600           #
#                                #
##################################
{pkgs, ...}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix

    # Modules
    ../../modules/nvidia-gpu/configuration.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };

  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    ("vfio-pci.ids="
      + builtins.concatStringsSep "," [
        "1002:7590" # RX 9060 XT
        "1002:ab40" # RX 9060 XT Audio

        "1002:7480" # PRO W7600
        "1002:ab30" # PRO W7600 Audio

        # "1912:0015" # USB Controllers
      ])
  ];
}
