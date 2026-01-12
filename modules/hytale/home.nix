{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.flatpaks.homeModules.default
  ];

  home.packages = [
    pkgs.flatpak
  ];

  home.sessionPath = [
    "$HOME/.local/share/flatpak/exports/bin"
    "/var/lib/flatpak/exports/bin"
  ];

  # Add Flatpak share directories to XDG_DATA_DIRS (as string)
  home.sessionVariables = {
    XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/share:/usr/local/share:$XDG_DATA_DIRS";
  };

  services.flatpak = {
    enable = true;
    forceRunOnActivation = true;

    packages = [
      ":${./packages/hytale-launcher-latest.flatpak}"
    ];
  };
}
