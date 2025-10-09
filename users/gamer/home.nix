{...}: {pkgs, ...}: {
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];

  home.file.".config/kscreenlockerrc".text = ''
    [Daemon]
    Autolock=false
    LockOnResume=false
    Timeout=0
  '';
}
