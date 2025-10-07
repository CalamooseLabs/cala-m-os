{config, ...}: let
  domain = "calamooselabs.com";

  vms = {
    "media" = {
      devices = ["arc-a310"];
      storage = 100; # GBs
      macID = "01";
      shares = [
        {
          proto = "virtiofs";
          tag = "acmecerts";
          source = "/var/lib/acme/${domain}";
          mountPoint = "/mnt/acme";
        }
      ];
    };
    "htpc" = {
      devices = ["rtx-5090"];
      storage = 100; # GBs
      macID = "02";
      shares = [
        {
          proto = "virtiofs";
          tag = "games";
          source = "/vm-data";
          mountPoint = "/mnt/games";
        }
      ];
    };
    "torrent" = {
      devices = [];
      storage = 100;
      macID = "03";
      shares = [];
    };
    "travel" = {
      devices = ["rtx-4060"];
      storage = 100; # GBs
      macID = "04";
      shares = [
        {
          proto = "virtiofs";
          tag = "games";
          source = "/vm-data";
          mountPoint = "/mnt/games";
        }
      ];
    };
  };

  bridgeInterface = "eno2";

  tokenPath = config.age.secrets.cloudflare-token.path;
in {
  imports = [
    ./secrets

    (import ../../services/vm-manager/default.nix {
      device_path = ./devices;
      vms = vms;
      networkInterface = bridgeInterface;
    })

    (import ../../services/certs/default.nix {
      domain = domain;
      tokenPath = tokenPath;
    })
  ];
}
