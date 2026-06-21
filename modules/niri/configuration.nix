{
  config,
  pkgs,
  ...
}: {
  # obs-kiosk is the shared modules/obs-kiosk (deduped with users/streamer).
  imports = [../obs-kiosk/configuration.nix];

  programs.niri.enable = true;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  # Login Service
  services.greetd.settings.default_session.command = "niri &> /dev/null";
}
