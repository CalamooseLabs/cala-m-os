##################################
#                                #
#   Hetzner Cloud (US, CCX)      #
#   TCI cloud fleet host         #
#                                #
##################################
{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix

    # Hetzner's routed (Layer 3) network + web-console-friendly boot; the host
    # sets its addresses via calamoose.hetznerCloud.* (DHCP until it does).
    ../../modules/hetzner-cloud/configuration.nix
  ];
}
