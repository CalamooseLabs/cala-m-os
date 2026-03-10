{pkgs, ...}: {
  home.packages = [
    pkgs.teleprompter
    pkgs.displaylink
  ];
}
