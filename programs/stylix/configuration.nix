{ inputs, pkgs, ... }:

{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = {
    enable = true;
    autoEnable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    image = ../../assets/wallpaper.png;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };

    fonts = {
      monospace = {
        package = pkgs.meslo-lg;
        name = "MesloLGS NF";
      };

      sansSerif = {
        package = pkgs.meslo-lg;
        name = "MesloLGS NF";
      };

      serif = {
        package = pkgs.meslo-lg;
        name = "MesloLGS NF";
      };
    };

    polarity = "dark";

    targets = {
      plymouth = {
        logo = ../../assets/logo-100x100.png;
      };
    };
  };
}
