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
    ../../modules/nvidia-gpu/configuration.nix # RTX PRO 4000 Blackwell
    ../../modules/amd-gpu/configuration.nix # AMD RX 9060 — the card the JetKVM is plugged into
  ];

  # NixOS owns all three NVMe drives here (boot + RAID0 recordings, see disko.nix),
  # so let the installer do an unattended full wipe. Default is false so dual-boot
  # machines are never auto-wiped.
  calamoose.install.wipeAllDisks = true;

  # NOTE: the gen2 "Switch root target contains no usable init" hang on this box
  # was NOT the kernel — it was the proton-secrets activation snippet doing
  # `exit 1` in the no-network initrd `activate`, aborting before /sysroot's
  # /etc was set up (fixed in antlers: its proton-secrets activation snippets
  # skip the initrd, where IN_NIXOS_SYSTEMD_STAGE1 is set, whatever failClosed
  # says; the secrets are fetched after switch-root, by
  # proton-secrets-fetch.service). gen2 failed identically on both 7.1 and
  # 6.18, so the earlier stable pin here was a red herring; run
  # linuxPackages_latest like the other workstations.
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
