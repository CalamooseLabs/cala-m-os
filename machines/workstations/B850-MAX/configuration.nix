##################################
#                                #
#      MSI B850 Tomahawk Max     #
#      AMD Ryzen 7 9800x3D       #
#         32GB DDR5 6400         #
#             RTX5090            #
#                                #
##################################
{pkgs, ...}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix

    # Modules
    ../../modules/nvidia-gpu/configuration.nix
    ../../modules/amd-cpu/configuration.nix
  ];

  hardware.nvidia.prime = {
    offload.enable = true;

    nvidiaBusId = "PCI:001:0:0";
    amdgpuBusId = "PCI:014:0:0";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── Install-time disk policy ────────────────────────────────────────────────
  # disko OWNS ONLY the OS drive (KIOXIA 1TB, pinned by-id in ./disko.nix), so a
  # full wipe is safe: it can never select the data drive below.
  calamoose.install.wipeAllDisks = true;

  # The WD SN850X 2TB is a PRESERVED data drive (games + DaVinci media). It is
  # kept OUT of disko so reinstalls never touch it — install-cala-m-os prompts
  # once (default KEEP) and only reformats on explicit confirmation.
  calamoose.install.dataDisks = [
    {
      device = "/dev/disk/by-id/nvme-WDS200T1X0E-00AFY0_22042X800647";
      label = "battle-data";
      fsType = "xfs";
    }
  ];

  # Mount the data drive by its filesystem label. `nofail` + a short device
  # timeout mean an absent or not-yet-formatted drive never blocks boot.
  fileSystems."/data" = {
    device = "/dev/disk/by-label/battle-data";
    fsType = "xfs";
    options = ["nofail" "x-systemd.device-timeout=5s"];
  };

  # Guarantee /data is writable by the primary user (hub) whenever the drive is
  # actually mounted — a backstop for the installer's KEEP path (which does not
  # chown) and for a disk formatted outside the installer. ConditionPathIsMountPoint
  # makes this a no-op when the data drive is absent (nofail left /data unmounted).
  systemd.services.data-ownership = {
    description = "Own /data by the primary user when the data drive is mounted";
    wantedBy = ["multi-user.target"];
    after = ["data.mount"];
    unitConfig.ConditionPathIsMountPoint = "/data";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/chown hub:users /data";
    };
  };
}
