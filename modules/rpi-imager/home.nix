{pkgs, ...}: {
  # Install rpi-imager with a wrapper that sets environment variables
  home.packages = [
    (pkgs.writeShellScriptBin "pi-imager" ''
      export QT_STYLE_OVERRIDE=fusion
      export QT_QPA_PLATFORM=wayland
      exec ${pkgs.rpi-imager}/bin/rpi-imager "$@"
    '')
  ];
}
