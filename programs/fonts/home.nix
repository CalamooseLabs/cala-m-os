{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    noto-fonts
    meslo-lgs-nf

    # All Nerd Fonts
    nerd-fonts.fantasque-sans-mono
    nerd-fonts.zed-mono
  ];
}
