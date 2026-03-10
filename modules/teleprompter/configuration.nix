{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    displaylink
  ];

  # evdi kernel module (required for DisplayLink on Wayland)
  boot = {
    extraModulePackages = [config.boot.kernelPackages.evdi];
    initrd.kernelModules = ["evdi"];
  };

  # DisplayLink Manager service
  systemd.services.dlm.wantedBy = ["multi-user.target"];
}
