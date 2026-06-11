{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.bitfocus-companion
  ];
}
