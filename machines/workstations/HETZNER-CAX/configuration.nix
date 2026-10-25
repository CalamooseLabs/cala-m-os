##################################
#                                #
#   Hetzner Cloud CAX (ARM64)    #
#   Ampere Altra KVM guest       #
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

  # The ARM kernel console defaults to serial, which Hetzner's web (VNC)
  # console can't show. Point it at the virtio-gpu framebuffer (qemu-guest loads
  # virtio_gpu in stage 1) so boot output and the login prompt are visible there.
  # Lives here, not in hardware-configuration.nix, so regenerating that file
  # with nixos-anywhere can't drop it.
  boot.kernelParams = ["console=tty"];

  # Bound ESP use: each boot entry carries a ~90 MiB kernel Image + initrd
  # (disko.nix), and nh only prunes generations weekly.
  boot.loader.systemd-boot.configurationLimit = 5;

  # 4 GB RAM and a 40 GB disk: compressed RAM swap instead of a swap partition.
  # Only on-box nix builds (--build-host) ever come close to needing it.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };
}
