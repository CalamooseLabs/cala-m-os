{
  config,
  pkgs,
  ...
}: {
  programs.niri.enable = true;

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "obs-kiosk" ''
      set -eux
      export LD_LIBRARY_PATH=/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      exec ${config.programs.obs-studio.finalPackage}/bin/obs
    '')
  ];

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  # Login Service
  services.greetd.settings.default_session.command = "niri &> /dev/null";
}
