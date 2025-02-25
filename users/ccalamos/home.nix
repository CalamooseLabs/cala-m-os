{ pkgs, ... }:


{
  home.packages = with pkgs; [
    proton-pass # Password Manager
    qutebrowser # VIM-like Browser
    imagemagick # Image manipulation
  ];

  catppuccin.enable = true;
}
