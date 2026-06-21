{
  cala-m-os,
  pkgs,
  lib,
  ...
}: let
  arrRestore = import ../arr-restore/restore.nix {inherit pkgs lib;};
in {
  services.radarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        port = 7878;
        bindaddress = "*";
      };
    };
  };

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/mnt/backups/radarr" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.backup.radarr}";
    fsType = "nfs";
  };

  # radarr-restore — rebuild state from the newest backup zip on the NAS share
  # (Radarr writes its own scheduled backups there). Mirrors plex-restore.
  environment.systemPackages = [
    (arrRestore {
      app = "radarr";
      db = "radarr.db";
      dataDir = "/var/lib/radarr/.config/Radarr";
      port = 7878;
      backup = "/mnt/backups/radarr";
    })
  ];
}
