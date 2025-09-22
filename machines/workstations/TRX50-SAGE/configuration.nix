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
{
  pkgs,
  cala-m-os,
  ...
}: {
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

    # Enable mdadm for RAID 0
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR <mailto:${cala-m-os.globalDefaultEmail}>
      '';
    };
  };
}
