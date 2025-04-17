{pkgs, ...}: {
  home.packages = with pkgs; [
    yubioath-flutter
    yubico-piv-tool
    yubikey-manager
  ];
}
