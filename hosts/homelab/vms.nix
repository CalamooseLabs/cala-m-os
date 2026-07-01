{
  config,
  cala-m-os,
  ...
}: let
  vms = {
    "media" = {
      devices = ["arc-b50"];
      # Plex gets the 10GbE port (eno1) to itself — its NAS reads and client
      # streams no longer share a physical uplink with the torrent VM.
      networkInterface = "eno1";
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
      # Cap TX so bulk *arr imports (local download dir → NFS library) can't
      # flood the NAS and stall Plex reads. ~1.5 Gbit/s leaves the array
      # headroom; this is a safety net until the hardlink layout removes the
      # import copy entirely, at which point it can be raised or dropped.
      egressRateLimit = "1500M";
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

  # Default uplink for guests (the 2.5GbE port): the torrent VM and any future
  # guests share this with the homelab host. The media VM overrides to eno1.
  bridgeInterface = "eno2";

  tokenPath = config.calamoose.secrets.cloudflare-token.path;
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
