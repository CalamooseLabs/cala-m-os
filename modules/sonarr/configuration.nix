{
  cala-m-os,
  pkgs,
  lib,
  ...
}: let
  arrRestore = import ../arr-restore/restore.nix {inherit pkgs lib;};
in {
  services.sonarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        port = 8989;
        bindaddress = "*";
      };
    };
  };

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/mnt/backups/sonarr" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.backup.sonarr}";
    fsType = "nfs";
  };

  # sonarr-restore — rebuild state from the newest backup zip on the NAS share
  # (Sonarr writes its own scheduled backups there). Mirrors plex-restore.
  environment.systemPackages = [
    (arrRestore {
      app = "sonarr";
      db = "sonarr.db";
      dataDir = "/var/lib/sonarr/.config/NzbDrone";
      port = 8989;
      backup = "/mnt/backups/sonarr";
    })
  ];
}
