##################################
#                                #
#        Zima Board 2 1664       #
#                                #
##################################
{pkgs, ...}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };
}
