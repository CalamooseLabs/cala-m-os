{inputs, ...}: {
  # moosefetch (antlers): the Cala-M-OS fastfetch wrapper. The readout is a list
  # of keywords that reads like this user's module imports — each entry is a
  # fastfetch module and a blank string "" inserts a spacer line. The logo is a
  # brand mark rendered to truecolor ANSI art at build time. See
  # github:CalamooseLabs/antlers#flakes/moosefetch.
  imports = [inputs.antlers.homeManagerModules.moosefetch];

  programs.moosefetch = {
    enable = true;
    logo = "cala-m-os"; # the gear + moose OS emblem

    modules = [
      "title"
      "separator"
      "os"
      "host"
      "kernel"
      "uptime"
      "packages"
      ""
      "de"
      "wm"
      "terminal"
      "shell"
      ""
      "cpu"
      "gpu"
      "memory"
      "swap"
      "disk"
      ""
      "battery"
      "poweradapter"
      "localip"
      ""
      "colors"
    ];
  };

  programs.bash.initExtra = "moosefetch";
}
