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

  services.flatpak = {
    enable = true;
    forceRunOnActivation = true;

    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "GeForceNOW" = "https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo";
    };

    packages = [
      "flathub:runtime/org.freedesktop.Sdk//24.08"
      "GeForceNOW:app/com.nvidia.geforcenow//master"
    ];

    overrides = {
      "com.nvidia.geforcenow" = {
        Context = {
          sockets = [
            "!wayland"
          ];
        };
      };
    };
  };
}
