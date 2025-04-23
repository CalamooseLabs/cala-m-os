{...}: {
  programs.vivaldi = {
    enable = true;
  };

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Web Content
      "text/html" = ["vivaldi-stable.desktop"];
      "x-scheme-handler/http" = ["vivaldi-stable.desktop"];
      "x-scheme-handler/https" = ["vivaldi-stable.desktop"];
    };
  };
}
