{
  config,
  pkgs,
  ...
}: let
  obsLauncher = pkgs.writeShellScript "obs-kiosk" ''
    export LD_LIBRARY_PATH=/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    exec ${config.programs.obs-studio.finalPackage}/bin/obs
  '';
in {
  home.packages = [obsLauncher];

  xdg.configFile."niri/config.kdl".source = ./config.kdl;
}
