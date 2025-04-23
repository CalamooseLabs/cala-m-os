{inputs, ...}: {
  home.packages = [
    inputs.antlers.packages.x86_64-linux.plex-desktop
  ];
}
