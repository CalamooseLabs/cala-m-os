{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    displaylink
  ];

  services.xserver.videoDrivers = ["displaylink" "modesetting"];

  # The upstream NixOS displaylink module (hardware/video/displaylink.nix) defines
  # dlm.service with only `after = display-manager.service` + `conflicts =
  # getty@tty7.service` and NO wantedBy/requiredBy. It was written for the Xorg
  # path, where the X display-manager pulls DisplayLinkManager in. Under a
  # pure-Wayland greetd -> Hyprland (UWSM) login there is no Xorg DM, so nothing
  # declares Wants=dlm and the daemon may never start at boot. With evdi loaded
  # but DisplayLinkManager not running, no frames are ever shipped over USB and
  # the teleprompter stays black. Pull it into the graphical boot explicitly.
  systemd.services.dlm.wantedBy = ["graphical.target"];
}
