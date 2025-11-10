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
{
  pkgs,
  config,
  ...
}: {
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
    "nvidia.modeset=1"
    "radeon.modeset=0"
    "amdgpu.modeset=0"
    "modprobe.blacklist=radeon"
    "modprobe.blacklist=amdgpu"
    "video=efifb:off" # Disable EFI framebuffer to prevent AMD from claiming it
    "video=vesafb:off"
    "video=simplefb:off"
    "amdgpu.sg_display=0" # Helps with RDNA3 reset issues
    "nokaslr"
    ("vfio-pci.ids="
      + builtins.concatStringsSep "," [
        "1002:7590" # RX 9060 XT
        "1002:ab40" # RX 9060 XT Audio

        "1002:7480" # PRO W7600
        "1002:ab30" # PRO W7600 Audio

        "1912:0015" # USB Controllers
      ])
  ];

  boot.extraModulePackages = with config.boot.kernelPackages; [vendor-reset];
  boot.kernelModules = ["vendor-reset"];
}
