{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.bitfocus-companion;

  # Build the argument list from the configured options, omitting unset values.
  args =
    [
      "--admin-port"
      (toString cfg.adminPort)
      "--admin-address"
      cfg.adminAddress
      "--config-dir"
      cfg.configDir
      "--log-level"
      cfg.logLevel
    ]
    ++ lib.optionals (cfg.adminInterface != null) ["--admin-interface" cfg.adminInterface]
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
  };

  config = lib.mkMerge [
    {
      # Keep the CLI available on the system regardless of the service.
      environment.systemPackages = [cfg.package];
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
