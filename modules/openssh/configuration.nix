{pkgs, ...}: {
  environment.systemPackages = [pkgs.ncurses];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      PubkeyAuthentication = true;
    };
  };
}
