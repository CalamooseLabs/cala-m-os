{...}: {
  programs.imv = {
    enable = true;
  };

  xdg.enable = true;
  xdg.mime.enable = true;

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Images
      "image/jpeg" = ["imv.desktop"];
      "image/png" = ["imv.desktop"];
      "image/gif" = ["imv.desktop"];
      "image/webp" = ["imv.desktop"];
    };
  };
}
