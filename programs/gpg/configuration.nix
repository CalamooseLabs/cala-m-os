{pkgs, ...}: {
  imports = [
    ./secrets
  ];

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry;
  };
}
