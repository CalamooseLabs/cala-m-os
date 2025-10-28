{
  config,
  cala-m-os,
  ...
}: let
  vms = {
    "media" = {
      devices = ["arc-a310"];
      storage = 100; # GBs
      macID = "10";
      ip = cala-m-os.ip.media;
      shares = [
        {
          proto = "virtiofs";
          tag = "acmecerts";
          source = "/var/lib/acme/${cala-m-os.fqdn}";
          mountPoint = "/mnt/acme";
        }
      ];
    };
    "htpc" = {
      devices = ["rtx-5090" "pci-usb-controller-1"];
      storage = 100; # GBs
      macID = "25";
      ip = cala-m-os.ip.htpc;
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
      macID = "35";
      ip = cala-m-os.ip.torrent;
      shares = [];
    };
    "studio" = {
      devices = ["rtx-4060" "pci-usb-controller-2"];
      storage = 100; # GBs
      macID = "30";
      ip = cala-m-os.ip.studio;
      shares = [
        {
          source = "/run/opengl-driver";
          mountPoint = "/run/opengl-driver";
          tag = "opengl";
          proto = "virtiofs";
        }
      ];
    };
    "vault" = {
      devices = [];
      storage = 100;
      macID = "20";
      ip = cala-m-os.ip.vault;
      shares = [];
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
      domain = cala-m-os.fqdn;
      tokenPath = tokenPath;
    })
  ];
}
