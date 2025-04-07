{pkgs, ...}: {
  home.packages = [
    pkgs.sops
    pkgs.age
    pkgs.age-plugin-yubikey
    # pkgs.age-plugin-fido2-hmac
  ];
}
