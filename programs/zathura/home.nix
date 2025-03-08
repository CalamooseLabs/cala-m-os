{ ... }:

{
    programs.zathura = {
        enable = true;
    };

    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        # PDFs
        "application/pdf" = ["org.pwmt.zathura.desktop"];
      };
    };
}
