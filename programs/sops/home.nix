{pkgs, ...}: {
  home.packages = [
    pkgs.sops
    pkgs.age-plugin-yubikey
  ];
}
