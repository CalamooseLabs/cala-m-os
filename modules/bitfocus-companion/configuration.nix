{
  config,
  lib,
  pkgs,
  cala-m-os,
  ...
}: let
  cfg = config.services.bitfocus-companion;

  # --admin-interface and --admin-address are mutually exclusive in Companion:
  # passing both is rejected, and the interface takes precedence when set.
  adminBindArgs =
    if cfg.adminInterface != null
    then ["--admin-interface" cfg.adminInterface]
    else ["--admin-address" cfg.adminAddress];

  # Build the argument list from the configured options, omitting unset values.
  args =
    [
      "--admin-port"
      (toString cfg.adminPort)
    ]
    ++ adminBindArgs
    ++ [
      "--config-dir"
      cfg.configDir
      "--log-level"
      cfg.logLevel
    ]
    ++ lib.optionals (cfg.extraModulePath != null) ["--extra-module-path" cfg.extraModulePath]
    ++ lib.optionals (cfg.machineId != null) ["--machine-id" cfg.machineId]
    ++ lib.optional cfg.disableAdminPassword "--disable-admin-password"
    ++ lib.optional cfg.disableNotifications "--no-notifications"
    ++ lib.optionals cfg.syslog.enable (
      ["--syslog-enable" "--syslog-host" cfg.syslog.host]
      ++ lib.optionals (cfg.syslog.port != null) ["--syslog-port" cfg.syslog.port]
      ++ lib.optional cfg.syslog.tcp "--syslog-tcp"
      ++ lib.optionals (cfg.syslog.localhost != null) ["--syslog-localhost" cfg.syslog.localhost]
    )
    ++ cfg.extraArgs;

  # Companion stores its live SQLite db under a per-release subdir of --config-dir:
  # `join(configDir, ConfigReleaseDirs[last])`, where the dir is `v<major.minor>`
  # (e.g. v4.3 for 4.3.x). On startup, if the current release dir has no db,
  # Companion migrates an older release's db forward — so a raw-db seed keeps
  # working across upgrades, and deriving the dir from the package version tracks
  # nixpkgs bumps automatically.
  dbVersionDir = "v" + lib.versions.majorMinor cfg.package.version;
  dbDir = "${cfg.configDir}/${dbVersionDir}";

  # ExecStartPre: seed the committed baseline db, but ONLY into a genuinely fresh
  # config (no db in the current or any prior release dir) — so an existing box's
  # live config, and Companion's own forward-migration, are never clobbered. Runs
  # as the service user; the store file is readable, install drops a writable copy.
  seedScript = pkgs.writeShellScript "companion-seed-db" ''
    set -eu
    base="${cfg.configDir}"
    dbdir="${dbDir}"
    if [ -n "$(${pkgs.findutils}/bin/find "$base" -maxdepth 2 \( -name db.sqlite -o -name db \) -print -quit 2>/dev/null)" ]; then
      exit 0
    fi
    ${pkgs.coreutils}/bin/mkdir -p "$dbdir"
    ${pkgs.coreutils}/bin/install -m 0600 "${toString cfg.seedDb}" "$dbdir/db.sqlite"
    echo "companion: seeded baseline db into $dbdir/db.sqlite"
  '';

  # Push the committed baseline back over the live db (stop, back up, swap, start).
  # The only reliable programmatic apply in v4.3: config import has no CLI/HTTP path.
  restoreCmd = pkgs.writeShellApplication {
    name = "companion-restore";
    runtimeInputs = [pkgs.coreutils pkgs.systemd pkgs.gnutar];
    text = ''
      if [ "$(id -u)" -ne 0 ]; then echo "run with sudo: sudo companion-restore" >&2; exit 1; fi
      src="${toString cfg.seedDb}"
      dbdir="${dbDir}"

      if [ "''${1:-}" != "--yes" ]; then
        printf 'This stops Companion and overwrites %s/db.sqlite\n' "$dbdir"
        printf 'with the committed baseline (a backup is taken first). Continue? [y/N] '
        read -r reply
        case "$reply" in [yY]*) ;; *) echo aborted; exit 1 ;; esac
      fi

      systemctl stop bitfocus-companion
      mkdir -p "$dbdir"
      if [ -e "$dbdir/db.sqlite" ]; then
        ts="$(date +%Y%m%d-%H%M%S)"
        tar czf "$dbdir/db.backup-$ts.tar.gz" -C "$dbdir" db.sqlite
        echo "backed up current db to $dbdir/db.backup-$ts.tar.gz"
      fi
      install -o ${cfg.user} -g ${cfg.group} -m 0600 "$src" "$dbdir/db.sqlite"
      # Stale WAL/SHM from the replaced db would corrupt the restored one.
      rm -f "$dbdir/db.sqlite-wal" "$dbdir/db.sqlite-shm"
      systemctl start bitfocus-companion
      echo "restored baseline db and restarted Companion"
    '';
  };

  # Snapshot the live db back into the repo working tree, committable afterwards.
  # sqlite3 .backup takes a consistent hot copy (WAL-safe) without stopping the show.
  snapshotCmd = pkgs.writeShellApplication {
    name = "companion-snapshot";
    runtimeInputs = [pkgs.coreutils pkgs.sqlite];
    text = ''
      if [ "$(id -u)" -ne 0 ]; then echo "run with sudo: sudo companion-snapshot" >&2; exit 1; fi
      repo="${toString cfg.repoPath}"
      dbdir="${dbDir}"
      if [ ! -e "$dbdir/db.sqlite" ]; then echo "no db at $dbdir/db.sqlite" >&2; exit 1; fi
      mkdir -p "$repo"
      sqlite3 "$dbdir/db.sqlite" ".backup '$repo/db.sqlite'"
      chown ${cala-m-os.globals.defaultUser}:${cala-m-os.globals.adminGroup} "$repo/db.sqlite"
      echo "snapshotted live db -> $repo/db.sqlite (git add + commit to make it the baseline)"
    '';
  };
in {
  options.services.bitfocus-companion = {
    enable =
      lib.mkEnableOption "Bitfocus Companion control surface server"
      // {default = true;};

    package = lib.mkPackageOption pkgs "bitfocus-companion" {};

    adminPort = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Port the admin UI should bind to.";
    };

    adminAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "IP address the admin UI should bind to.";
    };

    adminInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Network interface the admin UI should bind to. The first IP on this
        interface is used. Run `bitfocus-companion --list-interfaces` to see the
        available options. Overrides {option}`adminAddress` when set.
      '';
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bitfocus-companion";
      description = "Directory used for storing configuration.";
    };

    extraModulePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Extra directory to search for modules to load.";
    };

    machineId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Unique id for this installation.";
    };

    logLevel = lib.mkOption {
      type = lib.types.str;
      default = "info";
      description = "Log level to output to console.";
    };

    disableAdminPassword = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable password lockout for the admin UI.";
    };

    disableNotifications = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Don't show version-related notifications in the header.";
    };

    syslog = {
      enable = lib.mkEnableOption "syslog transport";

      host = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "Syslog server to write to.";
      };

      port = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Port on the syslog server to write to.";
      };

      tcp = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use TCP for transport instead of UDP.";
      };

      localhost = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hostname of this machine reported to syslog.";
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "bitfocus-companion";
      description = "User account under which Companion runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "bitfocus-companion";
      description = "Group under which Companion runs.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open {option}`adminPort` in the firewall.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["--disable-admin-password"];
      description = "Extra command-line arguments passed to bitfocus-companion.";
    };

    seedDb = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Store path of a committed Companion `db.sqlite` baseline. When set, it is
        seeded into the service's release dir on first start — but only when no db
        exists yet in any release dir, so an existing box is never clobbered. Also
        enables the `companion-restore` command. Null disables seeding.
      '';
    };

    repoPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/etc/nixos/machines/workstations/TRX50-SAGE/companion";
      description = ''
        Absolute working-tree directory that `companion-snapshot` writes the live
        `db.sqlite` into for committing. Null omits the snapshot command.
      '';
    };
  };

  config = lib.mkMerge [
    {
      # Keep the CLI available on the system regardless of the service.
      environment.systemPackages =
        [cfg.package]
        ++ lib.optional (cfg.seedDb != null) restoreCmd
        ++ lib.optional (cfg.repoPath != null) snapshotCmd;
    }

    (lib.mkIf cfg.enable {
      users.users = lib.mkIf (cfg.user == "bitfocus-companion") {
        bitfocus-companion = {
          isSystemUser = true;
          group = cfg.group;
          home = cfg.configDir;
        };
      };

      users.groups = lib.mkIf (cfg.group == "bitfocus-companion") {
        bitfocus-companion = {};
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.adminPort];

      systemd.services.bitfocus-companion = {
        description = "Bitfocus Companion";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];

        serviceConfig = {
          ExecStartPre = lib.mkIf (cfg.seedDb != null) [seedScript];
          ExecStart = "${lib.getExe cfg.package} ${lib.escapeShellArgs args}";
          User = cfg.user;
          Group = cfg.group;
          StateDirectory = lib.mkIf (cfg.configDir == "/var/lib/bitfocus-companion") "bitfocus-companion";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    })
  ];
}
