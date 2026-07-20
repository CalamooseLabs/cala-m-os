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
    ../../modules/amd-gpu/configuration.nix # AMD workstation GPU — Hyprland display + DisplayLink teleprompter render
  ];

  # NixOS owns all three NVMe drives here (boot + RAID0 recordings, see disko.nix),
  # so let the installer do an unattended full wipe. Default is false so dual-boot
  # machines are never auto-wiped.
  calamoose.install.wipeAllDisks = true;

  boot = {
    # linuxPackages_latest (kernel 7.1) HANGS this box in stage-1 with "switch
    # root target contains no usable init": the full config's gen2 loads its
    # kernel+initrd from the 990's systemd-boot but never hands off to init,
    # while the minimal install's gen1 on stable 6.18 boots fine from the SAME
    # menu. Kernel 7.1 itself is not the problem (devbox runs linuxPackages_latest
    # and boots) — it's a 7.1 regression specific to this box's hardware (RDNA4
    # RX 9060 + NVIDIA RTX Pro 4000 + NVMe RAID on TRX50). Pin to the stable
    # kernel gen1 already proves bootable here. Retry linuxPackages_latest once a
    # later 7.x lands (bump the nixpkgs input); keep this pin as the known-good.
    kernelPackages = pkgs.linuxPackages;
  };

  # Seed the committed Bitfocus Companion baseline (buttons/pages/connections) on a
  # fresh box, then let the machine own it — Companion's config already persists via
  # its StateDirectory, so live edits survive rebuilds. seedDb auto-wires once a
  # baseline db is committed (see ./companion/README.md); push it back with
  # `sudo companion-restore`, capture live changes with `sudo companion-snapshot`.
  services.bitfocus-companion = {
    seedDb = let
      p = ./companion/db.sqlite;
    in
      if builtins.pathExists p
      then p
      else null;
    repoPath = "/etc/nixos/machines/workstations/TRX50-SAGE/companion";
  };
}
