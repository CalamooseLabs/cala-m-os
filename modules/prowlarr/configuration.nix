{
  cala-m-os,
  pkgs,
  lib,
  ...
}: let
  arrRestore = import ../arr-restore/restore.nix {inherit pkgs lib;};
in {
  services.prowlarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        port = 9696;
        bindaddress = "*";
      };
    };
  };

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/mnt/backups/prowlarr" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.backup.prowlarr}";
    fsType = "nfs";
  };

  # prowlarr-restore — rebuild state from the newest backup zip on the NAS share
  # (Prowlarr writes its own scheduled backups there). Mirrors plex-restore.
  # dataDir resolves through systemd's DynamicUser StateDirectory symlink; the
  # script chowns restored files to match the dir's (runtime-allocated) owner.
  environment.systemPackages = [
    (arrRestore {
      app = "prowlarr";
      db = "prowlarr.db";
      dataDir = "/var/lib/prowlarr";
      port = 9696;
      backup = "/mnt/backups/prowlarr";
    })
  ];
}
