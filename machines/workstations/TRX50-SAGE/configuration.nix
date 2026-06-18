##################################
#                                #
#  ASUS Pro WS TRX50-Sage WiFi   #
#  AMD Ryzen Threadripper 7960X  #
#    64GB ECC DDR5 6000 CL32     #
#   RTX Pro 4000 Blackwell SFF   #
#                                #
##################################
{pkgs, ...}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix

    # Modules
    ../../modules/nvidia-gpu/configuration.nix # RTX PRO 4000 Blackwell — OBS/NVENC
    ../../modules/intel-gpu/configuration.nix # Arc A310 — niri display + DisplayLink teleprompter
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };
}
