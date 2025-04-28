{pkgs, ...}: {
  environment.systemPackages = [pkgs.displaylink];
  services.xserver.videoDrivers = ["displaylink" "modesetting"];
}
