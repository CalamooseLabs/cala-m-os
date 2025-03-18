{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = {
    enable = true;
    autoEnable = true;

    base16Scheme = {
      base00 = "#282828";
      base01 = "#383838";
      base02 = "#484848";
      base03 = "#4c4c4c";
      base04 = "#b8b8b8";
      base05 = "#eeeeee";
      base06 = "#e8e8e8";
      base07 = "#feffff";
      base08 = "#f43753";
      base09 = "#dc9656";
      base0A = "#ffc24b";
      base0B = "#c9d05c";
      base0C = "#73cef4";
      base0D = "#b3deef";
      base0E = "#d3b987";
      base0F = "#a16946";
    };

    image = ../../assets/wallpaper.png;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 16;
    };

    fonts = {
      monospace = {
        package = pkgs.meslo-lgs-nf;
        name = "MesloLGS NF";
      };

      sansSerif = {
        package = pkgs.meslo-lgs-nf;
        name = "MesloLGS NF";
      };

      serif = {
        package = pkgs.meslo-lgs-nf;
        name = "MesloLGS NF";
      };
    };

    polarity = "dark";

    targets = {
      plymouth = {
        logo = ../../assets/logo.png;
      };
    };

    opacity = {
      terminal = 0.9;
    };
  };
}
