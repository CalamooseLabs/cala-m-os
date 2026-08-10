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

    remotes = {
      # com.kagi.Orion pulls its GNOME runtime (org.gnome.Platform) from Flathub.
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      # Orion's own beta repo now ships a dedicated flatpak (no more vendored bundle).
      "orion-beta" = "https://flatpak.orionbrowser.com/orion-beta.flatpakrepo";
    };

    packages = [
      # Runtime dependency. Auto-pulled by the app install anyway, but pinned here so
      # the closure is explicit/deterministic — bump if Orion advances its GNOME runtime.
      "flathub:runtime/org.gnome.Platform//50"
      # Orion browser (dedicated flatpak, replaces the old vendored com.kagi.OrionGtk).
      "orion-beta:app/com.kagi.Orion//beta"
    ];
  };
}
