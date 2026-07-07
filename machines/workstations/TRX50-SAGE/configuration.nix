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
    kernelPackages = pkgs.linuxPackages_latest;
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
