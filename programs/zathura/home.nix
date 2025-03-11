{...}: {
  programs.zathura = {
    enable = true;

    options = {
      # Set clipboard provider to wl-copy (from wl-clipboard)
      selection-clipboard = "clipboard";
    };
  };

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # PDFs
      "application/pdf" = ["org.pwmt.zathura.desktop"];
    };
  };
}
