{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.qbittorrent-vpn;
in {
  options.services.qbittorrent-vpn = {
    enable = mkEnableOption "qBittorrent with WireGuard VPN";

    wireguardConfigFile = mkOption {
      type = types.path;
      description = "Path to WireGuard configuration file (complete wg-quick format with Address, PrivateKey, etc.)";
    };

    qbittorrentPasswordFile = mkOption {
      type = types.path;
      description = "Path to file containing qBittorrent WebUI PBKDF2 password hash";
    };

    webUI = {
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "WebUI port";
      };

      username = mkOption {
        type = types.str;
        default = "admin";
        description = "WebUI username";
      };
    };

    downloads = {
      path = mkOption {
        type = types.path;
        default = "/var/lib/qbittorrent/downloads";
        description = "Download directory";
      };

      incompletePath = mkOption {
        type = types.path;
        default = "/var/lib/qbittorrent/incomplete";
        description = "Incomplete downloads directory";
      };
    };

    torrentPort = mkOption {
      type = types.port;
      default = 6881;
      description = "BitTorrent port";
    };

    speedLimits = {
      globalDownload = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Global download speed limit in KB/s (null for unlimited)";
        example = 10240;
      };

      globalUpload = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Global upload speed limit in KB/s (null for unlimited)";
        example = 5120;
      };

      alternativeDownload = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Alternative download speed limit in KB/s for scheduled times";
      };

      alternativeUpload = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Alternative upload speed limit in KB/s for scheduled times";
      };

      enableScheduler = mkOption {
        type = types.bool;
        default = false;
        description = "Enable alternative speed limits scheduler";
      };

      scheduleFrom = mkOption {
        type = types.str;
        default = "20:00";
        description = "Start time for alternative speed limits (HH:MM format)";
      };

      scheduleTo = mkOption {
        type = types.str;
        default = "08:00";
        description = "End time for alternative speed limits (HH:MM format)";
      };
    };

    seedingLimits = {
      maxRatio = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Maximum share ratio (null for unlimited)";
        example = 2.0;
      };

      maxSeedingDays = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum seeding time in days (null for unlimited)";
        example = 7;
      };

      maxInactiveSeedingDays = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum inactive seeding time in days (null for unlimited)";
        example = 30;
      };

      actionOnLimit = mkOption {
        type = types.enum ["pause" "remove" "remove-with-files"];
        default = "pause";
        description = "Action when seeding limits are reached";
      };

      enableAutoDelete = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic torrent deletion when limits are reached";
      };
    };
  };

  config = mkIf cfg.enable {
    # **System configuration for namespace support**
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # **Create qBittorrent user and group**
    users.users.qbittorrent = {
      group = "qbittorrent";
      home = "/var/lib/qbittorrent";
      createHome = true;
      isSystemUser = true;
    };

    users.groups.qbittorrent = {};

    # **Ensure required packages are available**
    environment.systemPackages = with pkgs; [
      wireguard-tools
      iproute2
      iptables
    ];

    # **WireGuard network namespace service**
    systemd.services.wireguard-namespace = {
      description = "WireGuard VPN Network Namespace";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeScript "wireguard-namespace-start" ''
          #!${pkgs.bash}/bin/bash
          set -e  # Exit on any error

          echo "=== Starting WireGuard namespace setup (wg-quick method) ==="

          # **Cleanup previous state**
          echo "Cleaning up old namespace and interfaces..."
          ${pkgs.iproute2}/bin/ip link del veth-host 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip netns del vpn-qbt 2>/dev/null || true
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.200.200.0/24 -j MASQUERADE 2>/dev/null || true
          ${pkgs.iptables}/bin/iptables -D FORWARD -i veth-host -j ACCEPT 2>/dev/null || true
          ${pkgs.iptables}/bin/iptables -D FORWARD -o veth-host -j ACCEPT 2>/dev/null || true

          sleep 2

          # **Create network namespace**
          echo "Creating network namespace 'vpn-qbt'..."
          ${pkgs.iproute2}/bin/ip netns add vpn-qbt
          ${pkgs.iproute2}/bin/ip -n vpn-qbt link set lo up

          # **Create veth pair connecting namespace to host**
          echo "Creating veth pair..."
          ${pkgs.iproute2}/bin/ip link add veth-host type veth peer name veth-vpn
          ${pkgs.iproute2}/bin/ip link set veth-vpn netns vpn-qbt

          # Configure host side
          ${pkgs.iproute2}/bin/ip addr add 10.200.200.1/24 dev veth-host
          ${pkgs.iproute2}/bin/ip link set veth-host up

          # Configure namespace side
          ${pkgs.iproute2}/bin/ip -n vpn-qbt addr add 10.200.200.2/24 dev veth-vpn
          ${pkgs.iproute2}/bin/ip -n vpn-qbt link set veth-vpn up

          # **Set default route in namespace (initially through veth)**
          echo "Setting initial default route through veth..."
          ${pkgs.iproute2}/bin/ip -n vpn-qbt route add default via 10.200.200.1 dev veth-vpn

          # **Extract ProtonVPN endpoint IP for special routing**
          ENDPOINT_LINE=$(grep '^Endpoint' ${cfg.wireguardConfigFile})
          ENDPOINT_IP=$(echo "$ENDPOINT_LINE" | cut -d'=' -f2 | cut -d':' -f1 | xargs)
          ENDPOINT_PORT=$(echo "$ENDPOINT_LINE" | cut -d':' -f2 | xargs)
          echo "ProtonVPN endpoint: $ENDPOINT_IP:$ENDPOINT_PORT"

          # **CRITICAL: Add specific route for VPN endpoint through veth**
          echo "Adding route for VPN endpoint through veth..."
          ${pkgs.iproute2}/bin/ip -n vpn-qbt route add $ENDPOINT_IP/32 via 10.200.200.1 dev veth-vpn

          # **FIXED: Use proper filename for wg-quick**
          echo "Creating modified WireGuard config for namespace..."
          TEMP_CONFIG=/tmp/wg0.conf  # Must be named interface_name.conf

          # Copy config but:
          # 1. Remove DNS lines (causes issues in namespace)
          # 2. Add "Table = off" to prevent wg-quick from messing with routing
          {
            # Process Interface section
            sed -n '1,/^\[Peer\]/p' ${cfg.wireguardConfigFile} | head -n -1 | grep -v '^DNS'
            echo "Table = off"  # Prevent wg-quick from adding routes
            echo ""
            # Add Peer section as-is
            sed -n '/^\[Peer\]/,$p' ${cfg.wireguardConfigFile}
          } > "$TEMP_CONFIG"

          echo "Modified config created at $TEMP_CONFIG"

          # **Enable IP forwarding on HOST**
          echo "Enabling IP forwarding on host..."
          ${pkgs.procps}/bin/sysctl -w net.ipv4.ip_forward=1

          # **Setup NAT on HOST for namespace traffic**
          echo "Setting up NAT on host..."
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.200.200.0/24 -j MASQUERADE
          ${pkgs.iptables}/bin/iptables -I FORWARD -i veth-host -j ACCEPT
          ${pkgs.iptables}/bin/iptables -I FORWARD -o veth-host -j ACCEPT

          # **FIXED: Use the config file path directly**
          echo "Starting WireGuard with wg-quick..."
          ${pkgs.iproute2}/bin/ip netns exec vpn-qbt ${pkgs.wireguard-tools}/bin/wg-quick up "$TEMP_CONFIG"

          # **Update default route to use WireGuard (but keep endpoint through veth)**
          echo "Updating default route to use WireGuard tunnel..."
          ${pkgs.iproute2}/bin/ip -n vpn-qbt route del default 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip -n vpn-qbt route add default dev wg0

          # **Re-ensure endpoint still routes through veth (critical)**
          ${pkgs.iproute2}/bin/ip -n vpn-qbt route del $ENDPOINT_IP/32 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip -n vpn-qbt route add $ENDPOINT_IP/32 via 10.200.200.1 dev veth-vpn

          # **Clean up temp config**
          rm -f "$TEMP_CONFIG"

          # **Verify routing table**
          echo ""
          echo "=== Routing table in namespace ==="
          ${pkgs.iproute2}/bin/ip -n vpn-qbt route show

          # **Show WireGuard status**
          echo ""
          echo "=== WireGuard status ==="
          ${pkgs.iproute2}/bin/ip netns exec vpn-qbt ${pkgs.wireguard-tools}/bin/wg show

          # **Wait for handshake**
          echo ""
          echo "Waiting for handshake..."
          sleep 3

          echo "=== Setup complete ==="
          echo "To test: sudo ip netns exec vpn-qbt ping 1.1.1.1"
          echo "To check status: sudo ip netns exec vpn-qbt wg show"
        '';

        ExecStop = pkgs.writeScript "wireguard-namespace-stop" ''
          #!${pkgs.bash}/bin/bash

          echo "Stopping WireGuard in namespace..."

          # Stop WireGuard if running
          ${pkgs.iproute2}/bin/ip netns exec vpn-qbt ${pkgs.wireguard-tools}/bin/wg-quick down wg0 2>/dev/null || true

          # Clean up namespace and veth
          ${pkgs.iproute2}/bin/ip link del veth-host 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip netns del vpn-qbt 2>/dev/null || true

          # Clean up NAT rules
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.200.200.0/24 -j MASQUERADE 2>/dev/null || true
          ${pkgs.iptables}/bin/iptables -D FORWARD -i veth-host -j ACCEPT 2>/dev/null || true
          ${pkgs.iptables}/bin/iptables -D FORWARD -o veth-host -j ACCEPT 2>/dev/null || true

          echo "Cleanup complete"

          # **Read password from file**
          PASSWORD_HASH=$(sudo cat ${cfg.qbittorrentPasswordFile})
        '';

        # Restart policy
        Restart = "on-failure";
        RestartSec = "10s";
        StartLimitBurst = 3;
        StartLimitIntervalSec = 60;
      };
    };

    # **qBittorrent service**
    systemd.services.qbittorrent = {
      description = "qBittorrent BitTorrent Client in VPN";
      after = ["network-online.target" "wireguard-namespace.service"];
      wants = ["network-online.target"];
      requires = ["wireguard-namespace.service"];
      bindsTo = ["wireguard-namespace.service"];
      wantedBy = ["multi-user.target"];

      preStart = let
        # Convert action to numeric value
        actionValue =
          if cfg.seedingLimits.actionOnLimit == "pause"
          then "0"
          else if cfg.seedingLimits.actionOnLimit == "remove"
          then "1"
          else "2";

        # Convert days to minutes
        maxSeedingMinutes =
          if cfg.seedingLimits.maxSeedingDays != null
          then toString (cfg.seedingLimits.maxSeedingDays * 24 * 60)
          else "-1";
        maxInactiveSeedingMinutes =
          if cfg.seedingLimits.maxInactiveSeedingDays != null
          then toString (cfg.seedingLimits.maxInactiveSeedingDays * 24 * 60)
          else "-1";
      in ''
        # **Create necessary directories**
        mkdir -p /var/lib/qbittorrent/{config,downloads,incomplete,logs}
        mkdir -p ${cfg.downloads.path} ${cfg.downloads.incompletePath}

        # **Read password from file**
        # PASSWORD_HASH=$(sudo cat ${cfg.qbittorrentPasswordFile})

        # **Generate qBittorrent configuration**
        cat > /var/lib/qbittorrent/qBittorrent/config/qBittorrent.conf <<EOF
        [Application]
        FileLogger\Enabled=true
        FileLogger\Path=/var/lib/qbittorrent/logs
        FileLogger\MaxSizeBytes=10000000

        [BitTorrent]
        Session\BTProtocol=TCP
        Session\DefaultSavePath=${cfg.downloads.path}
        Session\TempPath=${cfg.downloads.incompletePath}
        Session\TempPathEnabled=true
        Session\Port=${toString cfg.torrentPort}
        Session\Interface=wg0
        Session\InterfaceName=wg0
        ${optionalString (cfg.speedLimits.globalDownload != null) ''
          Session\GlobalDLSpeedLimit=${toString cfg.speedLimits.globalDownload}
        ''}
        ${optionalString (cfg.speedLimits.globalUpload != null) ''
          Session\GlobalUPSpeedLimit=${toString cfg.speedLimits.globalUpload}
        ''}
        ${optionalString (cfg.speedLimits.alternativeDownload != null) ''
          Session\AlternativeGlobalDLSpeedLimit=${toString cfg.speedLimits.alternativeDownload}
        ''}
        ${optionalString (cfg.speedLimits.alternativeUpload != null) ''
          Session\AlternativeGlobalUPSpeedLimit=${toString cfg.speedLimits.alternativeUpload}
        ''}
        ${optionalString (cfg.seedingLimits.maxRatio != null) ''
          Session\GlobalMaxRatio=${toString cfg.seedingLimits.maxRatio}
          Session\MaxRatioEnabled=true
        ''}
        Session\MaxRatioAction=${actionValue}
        ${optionalString (cfg.seedingLimits.maxSeedingDays != null) ''
          Session\GlobalMaxSeedingMinutes=${maxSeedingMinutes}
        ''}
        ${optionalString (cfg.seedingLimits.maxInactiveSeedingDays != null) ''
          Session\GlobalMaxInactiveSeedingMinutes=${maxInactiveSeedingMinutes}
        ''}
        ${optionalString cfg.seedingLimits.enableAutoDelete ''
          Session\DeleteTorrentsFilesAsDefault=true
        ''}

        [Preferences]
        WebUI\Enabled=true
        WebUI\Port=${toString cfg.webUI.port}
        WebUI\Username=${cfg.webUI.username}
        WebUI\Password_PBKDF2=@ByteArray($PASSWORD_HASH)
        WebUI\LocalHostAuth=false
        WebUI\AuthSubnetWhitelistEnabled=true
        WebUI\AuthSubnetWhitelist=10.200.200.0/24,127.0.0.1/32
        WebUI\Address=10.200.200.2
        WebUI\CSRFProtection=false
        Downloads\SavePath=${cfg.downloads.path}
        Downloads\TempPath=${cfg.downloads.incompletePath}
        Downloads\TempPathEnabled=true
        Connection\PortRangeMin=${toString cfg.torrentPort}
        ${optionalString cfg.speedLimits.enableScheduler ''
          Scheduler\Enabled=true
          Scheduler\start_time=@Time(${cfg.speedLimits.scheduleFrom}:00)
          Scheduler\end_time=@Time(${cfg.speedLimits.scheduleTo}:00)
          Scheduler\days=EveryDay
        ''}
        EOF

        # **Set proper ownership**
        chown -R qbittorrent:qbittorrent /var/lib/qbittorrent
        chown -R qbittorrent:qbittorrent ${cfg.downloads.path} ${cfg.downloads.incompletePath} || true
        chmod 600 /var/lib/qbittorrent/config/qBittorrent.conf
      '';

      serviceConfig = {
        Type = "simple";
        User = "qbittorrent";
        Group = "qbittorrent";

        # **Run in the VPN namespace**
        NetworkNamespacePath = "/var/run/netns/vpn-qbt";
        PrivateNetwork = false;

        ExecStart = ''
          ${pkgs.qbittorrent-nox}/bin/qbittorrent-nox \
            --webui-port=${toString cfg.webUI.port} \
            --profile=/var/lib/qbittorrent
        '';

        Restart = "on-failure";
        RestartSec = "10s";

        # **Security hardening**
        # NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = [
          "/var/lib/qbittorrent"
          cfg.downloads.path
          cfg.downloads.incompletePath
        ];

        # Restart limits
        StartLimitBurst = 5;
        StartLimitIntervalSec = 30;
      };
    };
  };
}
