{...}: {
  programs.ghostty = {
    enable = true;
  };

  home.sessionVariables = {
    TERMINAL = "ghostty";
  };
}
