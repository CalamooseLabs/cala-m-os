{pkgs, ...}: {
  imports = [../../../../machines/modules/intel-gpu/configuration.nix];

  # The microVM guest otherwise boots the nixpkgs default kernel (6.18.x). That
  # already supports Battlemage (xe, device 8086:e212), so this is headroom, not
  # a fix — it pins the guest to match the host (linuxPackages_latest) for parity.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  microvm.devices = [
    {
      bus = "pci";
      path = "0000:03:00.0"; # Arc B50
    }
  ];
}
