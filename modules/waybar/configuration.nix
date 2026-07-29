{lib, ...}: {
  # Host-facing toggle for the waybar stream-privacy button (read by
  # modules/waybar/home.nix via osConfig, mirroring how it reads
  # osConfig.userSwitching.enable for the persona pill). System-side so a host
  # can flip it; the feature itself is a home-manager waybar module + a runtime
  # `hyprctl hyprpaper` wallpaper swap.
  options.cala.waybar.streamPrivacy.enable = lib.mkEnableOption ''
    the waybar stream-privacy toggle — a bar button that swaps the desktop
    wallpaper to The Company, Inc. brand wallpaper at runtime (no rebuild), so
    a personal photo background never lands on a stream. Flip it per-host
    (e.g. devbox). Click to hide/reveal; the swap is instant and reversible
    mid-stream
  '';
}
