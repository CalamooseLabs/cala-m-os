{ ... }:

{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    enableBashIntegration = true;
    enableFishIntegration = false;
    enableNushellIntegration = false;
    enableZshIntegration = false;

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "alphabetical";
        sort_dir_first = true;
      };
    };

  };
}
