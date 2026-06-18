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
  # NOTE(debug): logging temporarily un-silenced to diagnose the DisplayLink/evdi
  # output not being driven. Revert to "niri &> /dev/null" once resolved.
  services.greetd.settings.default_session.command = "env RUST_LOG=niri=debug,smithay=debug niri &> /tmp/niri-debug.log";
}
