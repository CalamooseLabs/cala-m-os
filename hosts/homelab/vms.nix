{
  config,
  cala-m-os,
  ...
}: let
  vms = {
    "media" = {
      devices = ["arc-b50"];
      storage = 100; # GBs
      shares = [
        {
          proto = "virtiofs";
          tag = "acmecerts";
          source = "/var/lib/acme/${cala-m-os.fqdn}";
          mountPoint = "/mnt/acme";
        }
      ];
    };
    "torrent" = {
      devices = [];
      storage = 100;
      shares = [
        {
          proto = "virtiofs";
          tag = "acmecerts";
          source = "/var/lib/acme/${cala-m-os.fqdn}";
          mountPoint = "/mnt/acme";
        }
      ];
    };
  };

  bridgeInterface = "eno2";

  tokenPath = config.age.secrets.cloudflare-token.path;
in {
  imports =
    [
      ./secrets
      ../../services/vm-manager
      ../../services/certs
    ]
    ++ (import ../../services/vm-manager/host-imports.nix {
      devicePath = ./devices;
      inherit vms;
    });

  services.cala-vm-manager = {
    enable = true;
    devicePath = ./devices;
    networkInterface = bridgeInterface;
    inherit vms;
  };

  services.cala-certs = {
    enable = true;
    domain = cala-m-os.fqdn;
    inherit tokenPath;
  };
}
