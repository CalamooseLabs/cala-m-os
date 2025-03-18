{pkgs, ...}: {
  home.packages = [
    pkgs.libreoffice-qt
    pkgs.hunspell
    pkgs.hunspellDicts.en_US
  ];
}
