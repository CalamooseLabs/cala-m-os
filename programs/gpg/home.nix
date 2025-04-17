{...}: {
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      "card-timeout" = "1";
      "disable-ccid" = true;
    };
  };
}
