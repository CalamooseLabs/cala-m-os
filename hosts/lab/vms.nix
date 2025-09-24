{config, ...}: let
  vms = {
    "media" = {
      devices = ["arc-a310"];
      storage = 100; # GBs
      macID = "01";
    };
  };

  bridgeInterface = "eno2";

  tokenPath = config.age.secrets.plex-cloudflare-token.path;
in {
  imports = [
    ./secrets

    (import ../../services/vm-manager/default.nix {
      device_path = ./devices;
      vms = vms;
      networkInterface = bridgeInterface;
      # Add additonal shares into vms to pass through
    })

    (import ../../services/cert/default.nix {
      domain = "calamooselabs.com";
      tokenPath = tokenPath;
      target = "localhost:32400";
      # Make this work with multiple
    })
  ];
}
