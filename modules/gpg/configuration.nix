{pkgs, lib, enable_secrets ? true, ...}: {
  imports = lib.optional enable_secrets ./secrets;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
  };
}
