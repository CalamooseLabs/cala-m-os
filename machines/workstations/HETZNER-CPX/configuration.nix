##################################
#                                #
#   Hetzner Cloud CPX (x86_64)   #
#   AMD EPYC KVM guest           #
#                                #
##################################
{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix

    # Hetzner's routed (Layer 3) network + web-console-friendly boot (and the
    # qemu-guest profile); the host sets its addresses via
    # calamoose.hetznerCloud.* (DHCP until it does).
    ../../modules/hetzner-cloud/configuration.nix
  ];

  # A 20 GB disk: keep few generations on the ESP and in the store (nh only
  # prunes weekly).
  boot.loader.systemd-boot.configurationLimit = 5;

  # The smallest types (CPX02: 1 GB RAM) leave little headroom, so compressed
  # RAM swap first, with the small swap partition from disko.nix behind it.
  # Nothing is built on the box (deploys build on devbox); this covers
  # activation and the occasional spike.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };
}
