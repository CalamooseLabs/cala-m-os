{pkgs, ...}: {
  home.packages = [
    pkgs.openssh
    pkgs.opensc
  ];

  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host github.com
        PKCS11Provider ${pkgs.opensc}/lib/opensc-pkcs11.so
    '';
  };

  programs.bash.shellAliases = {
    yubikey-ssh-add = "ssh-add -s ${pkgs.opensc}/lib/opensc-pkcs11.so";
  };
}
