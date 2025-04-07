{pkgs, ...}: {
  environment.systemPackages = [
    # pkgs.sops
    # pkgs.age
    # pkgs.age-plugin-yubikey
    pkgs.age-plugin-fido2-hmac
  ];
}
