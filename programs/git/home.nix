{...}: {
  programs.git = {
    enable = true;
    userName = "Cole J. Calamos";
    userEmail = "cole@calamos.family";
    signing = {
      key = "50D56BF0B93CA212";
      signByDefault = true;
    };
    extraConfig = {
      safe.directory = [
        "/etc/nixos"
      ];
    };
  };
}
