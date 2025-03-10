{...}: {
  programs.git = {
    enable = true;
    userName = "Cole J. Calamos";
    userEmail = "cole@calamos.family";
    signing = {
      key = "63C1F6DB3F13A405";
      signByDefault = true;
    };
    extraConfig = {
      safe.directory = [
        "/etc/nixos"
      ];
    };
  };
}
