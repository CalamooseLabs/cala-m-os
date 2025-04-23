{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
  ];

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Videos
      "video/mp4" = ["vlc.desktop"];
      "video/x-matroska" = ["vlc.desktop"];
      "video/webm" = ["vlc.desktop"];
    };
  };
}
