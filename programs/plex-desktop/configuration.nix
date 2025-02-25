{ pkgs, ... }:

{
  # Plex needs this to login/click on links.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      xdgOpenUsePortal = true;
    };
}
