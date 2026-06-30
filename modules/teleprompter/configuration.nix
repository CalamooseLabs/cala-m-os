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

  # Stable symlink to the DisplayLink/evdi card node. This belongs to the
  # teleprompter device itself, not any GPU (it was previously in the intel-gpu
  # module). A compositor given an explicit device allowlist must list the evdi
  # card too, or the teleprompter output is excluded — e.g. broadcast sets
  # AQ_DRM_DEVICES=/dev/dri/amd-card:/dev/dri/displaylink-card. card* numbering is
  # not stable across boots; matches nothing until an evdi device is present.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="evdi", SYMLINK+="dri/displaylink-card"
  '';
}
