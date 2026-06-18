{config, ...}: {
  programs.niri.settings = {
    spawn-at-startup = [
      {argv = ["librewolf"];}
    ];

    binds = with config.lib.niri.actions; {
      "Mod+T".action = spawn "ghostty";
      "Mod+B".action = spawn "librewolf";
      "Mod+Shift+F".action = fullscreen-window;
      "Mod+F".action = maximize-column;
      "Mod+M".action = maximize-window-to-edges;
    };
  };
}
